package game.data.photobooth
{
	import flash.display.Bitmap;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.utils.Dictionary;
	
	import engine.ShellApi;
	import engine.group.DisplayGroup;
	
	import game.data.character.ExpressionData;
	import game.data.character.LookConverter;
	import game.data.character.LookData;
	import game.data.character.LookParser;
	import game.data.character.PlayerLook;
	import game.ui.photo.CharacterPoseData;
	import game.util.BitmapUtils;
	import game.util.DataUtils;

	public class PhotoBoothData
	{
		public var assets:Array;
		public var poses:Array;
		public var expressions:Vector.<ExpressionData>;
		public var items:Vector.<LookData>;
		
		public var bgs:Vector.<StickerSheet>;
		public var stickers:Vector.<StickerSheet>;
		public var npcs:Vector.<StickerSheet>;
		public var templates:Vector.<StickerSheet>;
		
		public var fonts:Vector.<String>;
		public var sizes:Vector.<Number>;
		public var colors:Vector.<Number>;
		
		private static const TEMPLATE_PREFIX:String = "limited/_photobooth/templates/";
		
		public var templateDatas:Dictionary;
		
		public var startingTemplate:String;
		
		public var theme:*;// color or image to be used as a theme around image
		public var instructionsColor:Number = 0x98B9BC;
		public var music:String;
		
		public var headerData:HeaderData;
		
		public var submitPopup:DialogBoxData;
		
		public var promo:HeaderData;
		
		public var adCardEntered:String;
		public var adCardSaved:String;
		
		public function PhotoBoothData(xml:XML, shellApi:ShellApi)
		{
			assets = [];
			fonts = new Vector.<String>();
			sizes = new Vector.<Number>();
			colors = new Vector.<Number>();
			npcs = new Vector.<StickerSheet>();
			var lookConverter:LookConverter = new LookConverter();
			var playerLook:PlayerLook = shellApi.profileManager.active.look;
			if(playerLook != null)
			{
				var data:StickerAssetData = new StickerAssetData();
				data.id = "player";
				data.index = 0;
				data.tab="npcs";
				data.pose = 0;
				data.look = lookConverter.lookDataFromPlayerLook(playerLook);
				
				var sheet:StickerSheet = new StickerSheet();
				sheet.title = shellApi.profileManager.active.avatarName;
				sheet.stickers.push(data);
				npcs.push(sheet);
			}
			parse(xml);
		}
		
		public function parse(xml:XML):void
		{
			if(xml == null)
				return;
			
			theme = 0;
			
			if(xml.hasOwnProperty("@theme"))
			{
				theme = DataUtils.getNumber(xml.attribute("theme")[0]);
				if(isNaN(theme))
				{
					theme = DataUtils.getString(xml.attribute("theme")[0]);
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
			
			if(xml.hasOwnProperty("startingTemplate"))
				startingTemplate = DataUtils.getString(xml.child("startingTemplate")[0]);
			
			if(xml.hasOwnProperty("promo"))
				promo = new HeaderData(xml.child("promo")[0]);
			
			if(xml.hasOwnProperty("header"))
				headerData = new HeaderData(xml.child("header")[0]);
			
			poses = parseAssetList(xml, "poses", poses);
			
			var sheets:Array = ["bgs", "npcs", "stickers", "templates"];
			for each (var property:String in sheets)
			{
				this[property] = parseStickerSheet(xml.child(property)[0], property, this[property]);
			}
			
			var looksXML:XML = xml.child("looks")[0];
			
			expressions = parseExpressions( looksXML.child("facial"), "look",expressions);
			items = parseLookList( looksXML.child("item"), "look",items);
			
			var properties:Array = ["fonts", "sizes","colors"];
			for each( property in properties)
			{
				if(xml.hasOwnProperty(property))
					parsePropertyList(xml.child(property)[0].child(property.substr(0,property.length - 1)), this[property]);
			}
		}
		
		private function parsePropertyList(xmlList:XMLList, vector:*):void
		{
			if(xmlList != null)
			{
				for(var i:int = 0; i < xmlList.length(); i++)
				{
					vector.push(xmlList[i]);
				}
			}
		}
		
		private function parseExpressions(xmlList:XMLList, listName:String, facials:Vector.<ExpressionData>):Vector.<ExpressionData>
		{
			if(facials == null)
				facials = new Vector.<ExpressionData>();
			
			if(xmlList != null)
			{
				for(var i:int = 0; i < xmlList.length(); i++)
				{
					facials.push(new ExpressionData(xmlList[i].child(listName)[0]));
				}
			}
			
			return facials;
		}
		
		private function parseStickerSheet(xml:XML, tab:String, sheets:Vector.<StickerSheet> = null):Vector.<StickerSheet>
		{
			if(sheets == null)
				sheets = new Vector.<StickerSheet>();
			
			if(xml == null)
				return sheets;
			
			var sheet:StickerSheet;
			
			for(var i:int = 0; i < xml.children().length(); ++i)
			{
				sheet = new StickerSheet(xml.children()[i]);
				for each (var sticker:StickerAssetData in sheet.stickers)
				{
					sticker.tab = tab;
					sheets.length;
					if(sticker.asset != null)
						assets.push(sticker.asset);
					if(tab == "templates")
					{
						var assetUrl:String = TEMPLATE_PREFIX+sticker.id;
						if(assetUrl.indexOf(".xml") == -1)
							assetUrl += ".xml";
						assets.push(assetUrl);
					}
				}
				sheets.push(sheet);
			}
			
			return sheets;
		}
		
		private function parseLookList(xmlList:XMLList, listName:String, looks:Vector.<LookData> = null):Vector.<LookData>
		{
			if(looks == null)
				looks = new Vector.<LookData>();
			
			if(xmlList != null)
			{
				for(var i:int = 0; i < xmlList.length(); i++)
				{
					looks.push(new LookData(xmlList[i].child(listName)[0]));
				}
			}
			
			return looks;
		}
		
		private function parseAssetList(xml:XML, listName:String, assets:Array = null):Array
		{
			if(assets == null)
				assets = [];
			
			var assetList:XMLList = xml.child(listName)[0].child("asset");
			if(assetList != null)
			{
				for(var i:int = 0; i < assetList.length(); i++)
				{
					assets.push(assetList[i]);
				}
			}
			
			return assets;
		}
		
		public function setUpAssets(group:DisplayGroup):void
		{
			templateDatas = new Dictionary();
			
			var sheets:Array = ["bgs", "stickers", "templates"]; // npcs wont have an asset
			for each (var property:String in sheets)
			{
				setUpStickerSheets(group, this[property]);
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
			
			//setUpAssetList(group, poses);
			for(var i:int = 0 ; i < poses.length; i++)
			{
				var url:String = poses[i];
				var asset:DisplayObjectContainer = group.getAsset(url, true, true);
				var pose:CharacterPoseData = new CharacterPoseData(asset["pose"],false);
				pose.url= url;
				poses[i] = pose;
			}
			
			if(headerData != null)
				headerData.asset = group.getAsset(headerData.asset,true, true).getChildAt(0);
			
			if(promo != null)
				promo.asset = group.getAsset(promo.asset, true, true).getChildAt(0);
		}
		
		private function setUpStickerSheets(group:DisplayGroup, sheets:Vector.<StickerSheet>):void
		{
			var sheet:StickerSheet;
			var stickerData:StickerAssetData;
			for(var i:int = 0 ; i < sheets.length; ++i)
			{
				sheet = sheets[i];
				for(var j:int = 0 ; j < sheet.stickers.length; ++j)
				{
					stickerData = sheet.stickers[j];
					if(stickerData.asset != null)
						stickerData.asset = group.getAsset(stickerData.asset,true, true);
					if(stickerData.tab == "templates")
					{
						// center it in a movieclip
						if(stickerData.asset is Bitmap)
						{
							var asset:Bitmap = stickerData.asset as Bitmap;
							asset.x -= asset.width/2;
							asset.y -= asset.height/2;
							var clip:MovieClip = new MovieClip();
							clip.addChild(asset);
							stickerData.asset = clip;
						}
						templateDatas[stickerData.id] = new PhotoBoothSceneData(group.getData(TEMPLATE_PREFIX+stickerData.id+".xml",true, true));
					}
				}
			}
		}
		
		private function setUpAssetList(group:DisplayGroup, array:Array):void
		{
			for(var i:int = 0; i < array.length; i++)
			{
				array[i] = group.getAsset(array[i],true,true);
			}
		}
		
		public function getStickerAssetData(id:String, tab:String):StickerAssetData // looks through all the stickers in specified tab or all tabs if necesary
		{
			var assetData:StickerAssetData;
			
			if(["bgs", "stickers", "npcs"].indexOf(tab) == -1)
			{
				trace("ERROR:: " + tab + " is not a valid tab.");
				return null;
			}
			
			var stickers:Vector.<StickerSheet> = this[tab];
			
			for each(var sheet:StickerSheet in stickers)
			{
				assetData = sheet.getStickerById(id);
				if(assetData != null)
					break;
			}
			return assetData;
		}
		
		public function destroy():void
		{
			assets = null;
			poses = null;
			expressions = null;
			items = null;
			while(bgs.length > 0)
			{
				bgs.pop().destroy();
			}
			while(stickers.length > 0)
			{
				stickers.pop().destroy();
			}
			while(npcs.length > 0)
			{
				npcs.pop().destroy();
			}
			while(templates.length > 0)
			{
				templates.pop().destroy();
			}
			bgs = null;
			stickers = null;
			npcs = null;
			templates = null;
			fonts = null;
			sizes = null;
			colors = null;
			templateDatas = null;
		}
	}
}