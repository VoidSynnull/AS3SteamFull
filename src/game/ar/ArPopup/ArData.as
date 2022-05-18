package game.ar.ArPopup
{
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.utils.Dictionary;
	
	import engine.ShellApi;
	import engine.group.DisplayGroup;
	
	import game.data.photobooth.DialogBoxData;
	import game.util.BitmapUtils;
	import game.util.DataUtils;

	public class ArData
	{
		public var assets:Array;
		public var theme:*;// color or image to be used as a theme around image
		public var instructionsColor:Number = 0x98B9BC;
		public var music:String;
		
		public var submitPopup:DialogBoxData;
		
		public var logo:LogoData;
		
		public var adCardEntered:String;
		public var adCardSaved:String;
		
		public var masks:Vector.<ArAsset>;
		public var landMarkers:Vector.<int>;
		
		public function ArData(xml:XML, shellApi:ShellApi)
		{
			assets = [];
			parse(xml);
		}
		
		public function parse(xml:XML):void
		{
			masks = new Vector.<ArAsset>();
			landMarkers = new Vector.<int>();
			if(xml == null)
				return;
			
			theme = 0;
			
			if(xml.hasOwnProperty("@theme"))
			{
				theme = DataUtils.getNumber(xml.attribute("theme")[0]);
				if(isNaN(theme))
				{
					theme = DataUtils.getString(xml.attribute("theme")[0]);
					assets.push(theme);
				}
			}
			
			if(xml.hasOwnProperty("@instructionsColor"))
			{
				instructionsColor = DataUtils.getNumber(xml.attribute("instructionsColor")[0]);
			}
			
			if(xml.hasOwnProperty("adCardEntered"))
			{
				adCardEntered = DataUtils.getString(xml.child("adCardEntered")[0]);
				if(adCardEntered.indexOf("item") != 0)
					adCardEntered = "item"+adCardEntered;
			}
			
			if(xml.hasOwnProperty("adCardSaved"))
			{
				adCardSaved = DataUtils.getString(xml.child("adCardSaved")[0]);
				if(adCardSaved.indexOf("item") != 0)
					adCardSaved = "item"+adCardSaved;
			}
			
			if(xml.hasOwnProperty("music"))
				music = DataUtils.getString(xml.child("music")[0]);
			
			if(xml.hasOwnProperty("submitPopup"))
				submitPopup = new DialogBoxData(xml.child("submitPopup")[0]);
			
			if(xml.hasOwnProperty("logo"))
			{
				logo = new LogoData(xml.child("logo")[0]);
				assets.push(logo.asset);
			}
			
			if(xml.hasOwnProperty("masks"))
			{
				var masksXML:XML = xml.child("masks")[0];
				for(var i:int = 0; i < masksXML.children().length();i++)
				{
					var asset:ArAsset = new ArAsset(masksXML.children()[i]);
					masks.push(asset);
					if(assets.indexOf(asset.asset) == -1)
						assets.push(asset.asset);
					if(landMarkers.indexOf(asset.position.node) == -1)// add all the unique land mark nodes into a list
						landMarkers.push(asset.position.node);
				}
			}
		}
		
		public function setUpPrelimAssets(group:DisplayGroup):void
		{
			if(isNaN(theme))
			{
				theme = group.getAsset(theme,true,true);
				if(theme is Bitmap)
					theme = Bitmap(theme).bitmapData;
				else
					theme = BitmapUtils.createBitmapData(theme);
			}
			
			if(logo != null)
				logo.asset = group.getAsset(logo.asset, true, true).getChildAt(0);
			
			var loadedAssets:Dictionary = new Dictionary();
			
			for(var i:int = 0; i < masks.length; i++)
			{
				var asset:DisplayObject = group.getAsset(masks[i].asset,true, true);
				if(asset != null)
				{
					loadedAssets[masks[i].asset] = asset;
				}
				else if(loadedAssets.hasOwnProperty(masks[i].asset))
				{
					asset = loadedAssets[masks[i].asset];
				}
				
				if(asset is DisplayObjectContainer)
					asset = DisplayObjectContainer(asset).getChildAt(0);
				
				if(asset is Bitmap)
				{
					var sprite:Sprite = new Sprite();
					sprite.addChild(asset);
					asset.x = -asset.width /2;
					asset.y = -asset.height/2;
					asset = sprite;
				}
				
				masks[i].asset = asset;
			}
		}
		
		public function getMaskById(id:String):ArAsset
		{
			for(var i:int = 0; i < masks.length; i++)
			{
				if(masks[i].id == id)
					return masks[i];
			}
			return null;
		}
	}
}