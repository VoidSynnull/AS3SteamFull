package game.scenes.hub.profile.groups
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.geom.Rectangle;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import engine.group.DisplayGroup;
	import engine.util.Command;
	
	import game.data.photobooth.PhotoBoothSceneData;
	import game.data.photobooth.StickerData;
	import game.data.character.LookData;
	import game.data.display.SpatialData;
	import game.data.profile.ProfileData;
	import game.scene.template.CharacterGroup;
	import game.ui.photo.CharacterPoseData;
	import game.util.CharUtils;
	import game.util.DataUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	
	public class PhotoBoardGroup extends DisplayGroup
	{
		public var picDatas:Dictionary;//photoName:PhotoBoothSceneData
		public var boothDatas:Dictionary;//campaignName:PhotoBoothData
		public var pictures:Dictionary;//photoName:BitmapData
		public var assets:Dictionary;
		
		public static const GROUP_ID:String = "PhotoBoardGroup";
		private static const GROUP_SIZE:int =6;
		
		private var charGroup:CharacterGroup;
		private var dummy:Entity;
		private var cmsData:Object;
		
		private var index:int = 0;
		private var numTemplates:int = 0;
		public var login:String;
		
		public function get NumTemplates():int{return numTemplates;}
		
		public function PhotoBoardGroup(container:DisplayObjectContainer=null, login:String = null)
		{
			super(container);
			picDatas = new Dictionary();
			boothDatas = new Dictionary();
			pictures = new Dictionary();
			assets = new Dictionary();
			id = GROUP_ID;
			this.login = login;
		}
		
		override public function destroy():void
		{
			picDatas= null;
			boothDatas = null;
			pictures = null;
			assets = null;
			cmsData = null;
			charGroup = null;
			dummy = null;
			
			super.destroy();
		}
		
		override public function init(container:DisplayObjectContainer=null):void
		{
			super.init(container);
			callToServer();
		}
		
		private function callToServer():void
		{
			var profile:ProfileData = shellApi.profileManager.active;
			if(profile.isGuest)
			{
				super.loaded();
				return;
			}
			var postVars:URLVariables = new URLVariables();
			
			postVars.login = profile.login;
			postVars.pass_hash = profile.pass_hash;
			postVars.dbid = profile.dbid;
			postVars.limit = GROUP_SIZE;
			postVars.last_seq = index;
			if(DataUtils.validString(login))
				postVars.lookup_user = login;
			
			var url:String = super.shellApi.siteProxy.secureHost + "/interface/PhotoBooth/get";
			var req:URLRequest = new URLRequest(url);
			req.method = URLRequestMethod.POST;
			req.data = postVars;
			
			var loader:URLLoader = new URLLoader(req);
			loader.addEventListener(Event.COMPLETE,onPicDataRetrieved);
			loader.addEventListener(IOErrorEvent.IO_ERROR, onPicDataRetrievalError);
			loader.load(req);
		}
		
		public static function sortByDate(a:String, b:String):int
		{
			var index:int = a.indexOf("_");
			var val:String = a.substr(index+1);
			var dateA:int = getIntFromDate(val);
			
			index = b.indexOf("_");
			val = b.substr(index+1);
			var dateB:int = getIntFromDate(val);
			// want latest dates first (newer to oldest)
			if(dateA < dateB)
				return 1;
			else
				return -1;
		}
		
		private static function getIntFromDate(dateString:String):int
		{
			var val:int = 0;
			//have to correct date string due to naming convention requirements
			while(dateString.indexOf("-") > -1)
			{
				dateString = dateString.replace("-",":");
			}
			val = Date.parse(dateString);
			return val;
		}
		
		public function retrieveMorePics(index:int):void
		{
			this.index = index;
			callToServer();
		}
		
		private function onPicDataRetrieved(e:Event):void
		{
			var data:Object = JSON.parse(e.target.data);
			var pics:Array = data.photos;
			numTemplates = data.total;
			cmsData = data;
			if(pics == null || pics.length == 0)
			{
				prelimAssetsLoaded();
				return;
			}
			
			onDataFilesLoaded();
		}
		
		private function onDataFilesLoaded():void
		{
			var pics:Array = cmsData.photos;
			var files:Array = [];
			var xml:XML;
			for(var i:int = 0; i < pics.length; i++)
			{
				var picData:Object = pics[i];
				
				if(!picDatas.hasOwnProperty(picData.photo_name))
				{
					picData.photo = new XML(picData.photo);
					trace(picData.photo);
					var photoData:PhotoBoothSceneData = new PhotoBoothSceneData(picData.photo);
					picDatas[picData.photo_name] = photoData;
					determineNeededAssets(photoData, files);
				}
			}
			
			if(files.length >0)
				loadFiles(files,false,true,prelimAssetsLoaded);
			else
				prelimAssetsLoaded();
		}
		
		private function determineNeededAssets(picData:PhotoBoothSceneData, files:Array):void
		{
			var asset:String;
			for(var i:int = 0; i< picData.sceneStickers.length; i++)
			{
				var sticker:StickerData = picData.sceneStickers[i];
				
				asset = sticker.asset.url;
				if( files.indexOf(asset) == -1 && !assets.hasOwnProperty(asset))// if not already added to the list add it
					files.push(sticker.asset.asset);
			}
			
			asset = picData.bg.asset.url;
			
			if( files.indexOf(asset) == -1 && !assets.hasOwnProperty(asset))
				files.push(asset);
		}
		
		private function prelimAssetsLoaded():void
		{
			// only set up the first time
			if(charGroup != null)
			{
				ready.dispatch(this);
				return;
			}
			
			charGroup = new CharacterGroup();
			charGroup.id = "photoCharGroup";
			charGroup.setupGroup(this, new Sprite());
			charGroup.createDummy("player",new LookData(),"right","",null,null,dummyLoaded,true, .55);
		}
		
		private function dummyLoaded(entity:Entity):void
		{
			dummy = entity;
			super.loaded();
		}
		
		public function recreatePhoto(photoName:String, onComplete:Function):void
		{
			var bitmapData:BitmapData = null;
			if(pictures.hasOwnProperty(photoName))
			{
				bitmapData = pictures[photoName];
			}
			var photoData:PhotoBoothSceneData = null;
			if(picDatas.hasOwnProperty(photoName))
			{
				photoData = picDatas[photoName];
			}
			
			if(photoData == null)
			{
				trace("There is no template by the name " + photoName);
				onComplete(null);
				return;
			}
			
			var sprite:Sprite = new Sprite();
			
			if(bitmapData)
			{
				sprite.addChild(centerBitmap(bitmapData));
				onComplete(sprite);
				return;
			}
			trace("Recreate " +  photoName);
			photoData.stickerNumber = 0;
			createSticker(photoData.bg, sprite, Command.create(recreateSceneStickers, photoData, sprite, photoName, onComplete));
		}
		
		private function recreateSceneStickers(photoData:PhotoBoothSceneData, sceneContainer:DisplayObjectContainer, photoName:String, onComplete:Function):void
		{
			trace(photoData.stickerNumber + "/" + photoData.sceneStickers.length);
			if(photoData.stickerNumber < photoData.sceneStickers.length)
			{
				var sticker:StickerData = photoData.sceneStickers[photoData.stickerNumber];
				photoData.stickerNumber++;
				createSticker(sticker, sceneContainer, Command.create(recreateSceneStickers, photoData, sceneContainer, photoName, onComplete));
			}
			else
			{
				var bitmapData:BitmapData = createBitmapData(sceneContainer,1,new Rectangle(-360, -240, 720, 480));
				var sprite:Sprite = new Sprite();
				sprite.addChild(centerBitmap(bitmapData));
				pictures[photoName] = bitmapData;
				onComplete(sprite);
			}
		}
		
		private function createSticker(sticker:StickerData, sceneContainer:DisplayObjectContainer, onComplete:Function):void
		{
			if(sticker.asset.look != null)
			{
				SkinUtils.applyLook(dummy, sticker.asset.look, true, Command.create(onLookApplied, sticker, sceneContainer, onComplete))
			}
			else
			{
				var data:BitmapData;
				var asset:DisplayObjectContainer;
				var sprite:Sprite = new Sprite();
				var frame:MovieClip;
				if(assets.hasOwnProperty(sticker.asset.url))
				{
					asset = assets[sticker.asset.url];
				}
				else
				{
					asset = getAsset(sticker.asset.url,true);
					
					assets[sticker.asset.url] = asset;
				}
				
				var rect:Rectangle = null;
				
				if(sticker.asset.tab == "bgs")
				{
					frame = asset["frame"];
					if(frame)
					{
						rect = frame.getBounds(frame);
						asset.removeChild(frame);
					}
				}
				var scale:Number = sticker.position.scale;
				data = createBitmapData(asset,scale,rect);
				if(frame)
					asset.addChild(frame);
				
				sprite.addChild(centerBitmap(data, 1/scale));
				sprite.alpha = sticker.asset.alpha;
				sceneContainer.addChild(sprite);
				positionSticker(sprite, sticker.position);
				
				onComplete();
			}
		}
		
		private function onLookApplied(entity:Entity, sticker:StickerData, sceneContainer:DisplayObjectContainer, onComplete:Function):void
		{
			var pose:CharacterPoseData;
			if(assets.hasOwnProperty(sticker.asset.url))
			{
				pose = assets[sticker.asset.url];
			}
			else
			{
				var asset:DisplayObjectContainer = getAsset(sticker.asset.url,true);
				pose = new CharacterPoseData(asset["pose"], false);
				assets[sticker.asset.url] = pose;
			}
			
			if(sticker.asset.expression != null)
				SkinUtils.setEyeStates(dummy, sticker.asset.look.getValue(SkinUtils.EYE_STATE), sticker.asset.expression.pupilState,true);
			
			CharUtils.poseCharacter(dummy, pose);
			SceneUtil.delay(this, 4, function():void
			{
				var sprite:Sprite = createBitmapSprite(EntityUtils.getDisplayObject(dummy),sticker.position.scale,null,true,0,null);
				var bitmap:Bitmap = sprite.getChildAt(0) as Bitmap;
				bitmap.smoothing = true;
				sprite.alpha = sticker.asset.alpha;
				sceneContainer.addChild(sprite);
				positionSticker(sprite, sticker.position);
				onComplete();
			}).countByUpdate = true;
		}
		
		private function positionSticker(sticker:Sprite, spatialData:SpatialData):void
		{
			// something about creating entities and having spatial data position accordingly
			// was running into issues mid way through the loading process, so i just took out the middle man
			for(var i:int = 0; i < SpatialData.SPATIAL_PROPERTIES.length - 1; i++)
			{
				var prop:String = SpatialData.SPATIAL_PROPERTIES[i];
				sticker[prop] = spatialData[prop];
			}
		}
		
		private function centerBitmap(bitmapData:BitmapData, scale:Number = 1):Bitmap
		{
			var bitmap:Bitmap = new Bitmap(bitmapData, "auto", true);
			bitmap.smoothing = true;
			bitmap.scaleX = bitmap.scaleY = scale;
			bitmap.x = -bitmap.width/2;
			bitmap.y = -bitmap.height/2;
			return bitmap;
		}
		
		private function onPicDataRetrievalError(e:Error):void
		{
			trace(e.getStackTrace());
		}
	}
}