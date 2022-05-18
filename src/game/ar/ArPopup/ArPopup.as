package game.ar.ArPopup
{
	import com.adobe.images.PNGEncoder;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.media.Camera;
	import flash.net.FileReference;
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.timeline.BitmapSequence;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.display.BitmapWrapper;
	import game.managers.interfaces.IAdManager;
	import game.scene.template.ItemGroup;
	import game.scene.template.ui.CardGroup;
	import game.systems.timeline.BitmapSequenceSystem;
	import game.systems.timeline.TimelineControlSystem;
	import game.ui.elements.ConfirmationDialogBox;
	import game.ui.popup.Popup;
	import game.ui.screenCapture.CaptionData;
	import game.util.AudioUtils;
	import game.util.BitmapUtils;
	import game.util.DataUtils;
	import game.util.DisplayPositions;
	import game.util.EntityUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	
	public class ArPopup extends Popup
	{
		private var dataPath:String;
		private var campaign:String;
		
		private var content:MovieClip;
		private var scene:MovieClip;
		private var border:MovieClip;
		private var header:MovieClip;
		private var promo:MovieClip;
		private var maskContainer:MovieClip;
		
		private var itemGroup:ItemGroup;
		// ar management
		private var arEffect:ArEffect;
		
		private var bitmaps:Dictionary;
		
		private var arData:ArData;
		private var picData:BitmapData;
		private var photoNumber:Number = 0;
		
		//private var faces : Vector.<BRFFace>;
		
		private var cameraPermissionsConfirmed:Boolean = false;
		
		//sounds
		private const CLICK_EXIT:String = "ui_close_cancel.mp3";
		private const CLICK_SAVE:String = "photo_shoot_01.mp3";
		
		public function ArPopup(container:DisplayObjectContainer, dataPath:String, campaign:String = null)
		{
			trace("ArPopup started");
			super(container);
			screenAsset = "ar_popup.swf";
			groupPrefix = "ar/";
			configData(dataPath, campaign);
		}
		
		override public function destroy():void
		{
			super.destroy();
			arEffect.destroy();
			bitmaps = null;
			//faces = null;
		}
		
		override public function init(container:DisplayObjectContainer=null):void
		{
			this.darkenBackground 	= true;
			this.darkenAlpha = 1;
			super.init(container);
			if(data != null)
			{
				configData(data.path, data.campaign);
			}
			load();
		}
		
		private function configData(dataPath:String, campaign:String):void
		{
			this.dataPath = dataPath;
			if(campaign != null)
				this.campaign = campaign;
			else
			{
				var prefix:String = "data/limited/";
				var suffix:String = "/ar.xml"
				this.campaign = dataPath.substring(prefix.length, dataPath.length - suffix.length);
			}
		}
		
		override public function load():void
		{
			trace("load data for " + campaign + " from: " + dataPath);
			shellApi.loadFile(dataPath, setUpData);
		}
		
		private function setUpData(xml:XML):void
		{
			trace("set up " + xml);
			arData = new ArData(xml, shellApi);
			var assets:Array = arData.assets.concat(groupPrefix+screenAsset);
			
			loadFiles(assets, true, true, loaded);
		}
		
		override public function loaded():void
		{
			super.screen = super.getAsset(super.screenAsset, true) as MovieClip;
			content = screen.content;
			arData.setUpPrelimAssets(this);
			
			if(arData.music != null)
				AudioUtils.play(this, SoundManager.MUSIC_PATH+arData.music, 1, true);
			
			trace(campaign);
			IAdManager(shellApi.adManager).track(campaign, "ArBoothOpened");
			
			maskContainer = content["masks"];
			maskContainer.x = shellApi.viewportWidth -110;
			
			var clip:DisplayObjectContainer = content["scene"];
			clip.x = (shellApi.viewportWidth) / 2;
			
			// save button
			clip = content["printBtn"];
			pinToEdge(clip, DisplayPositions.BOTTOM_RIGHT,30,30);
			ButtonCreator.createButtonEntity(clip,this);
			clip.addEventListener(MouseEvent.CLICK,savePhoto);
			
			//close button
			clip = content["closeBtn"];
			pinToEdge(clip, DisplayPositions.TOP_RIGHT,30,30);
			ButtonCreator.createButtonEntity(clip,this, closeButtonClicked);
			
			scene = content["scene"]["container"];
			border = content["scene"]["border"];
			border.mouseChildren = border.mouseEnabled = false;
			
			border.width = shellApi.viewportWidth;
			border.height = shellApi.viewportHeight;
			
			if(arData.logo != null)
			{
				var image:DisplayObjectContainer = scene.parent;
				var rect:Rectangle = border.getRect(border.parent);
				var logo:DisplayObject = arData.logo.asset;
				image.addChild(logo);
				if(arData.logo.percent)
				{
					logo.x = rect.left + rect.width * arData.logo.position.x;
					logo.y = rect.top + rect.height * arData.logo.position.y;
				}
				else
				{
					logo.x = rect.left + arData.logo.position.x;
					logo.y = rect.top + arData.logo.position.y;
				}
			}
			itemGroup = getGroupById(ItemGroup.GROUP_ID) as ItemGroup;
			
			if(DataUtils.validString(arData.adCardEntered))
			{
				if(!shellApi.checkHasItem(arData.adCardEntered, CardGroup.CUSTOM))
					itemGroup.showAndGetItem(arData.adCardEntered, CardGroup.CUSTOM, null, screen);
			}
			
			addSystem( new BitmapSequenceSystem());
			addSystem(new TimelineControlSystem());
			
			setUpAr();
		}
		
		private function setUpMasks():void
		{
		//	faces = arEffect.arManager.getFaces();
			bitmaps = new Dictionary();
			var mask:DisplayObject;
			var entity:Entity;
			var interaction:Interaction;
			var spatial:Spatial;
			
			var rect:Rectangle = new Rectangle(10,70,80,shellApi.viewportHeight - 160);
			
			for(var i:int = 0; i < arData.masks.length; i++)
			{
				var assetData:ArAsset = arData.masks[i]
				mask = assetData.asset;
				if(mask == null)
					continue;
				
				if(mask is Bitmap)
				{
					Bitmap(mask).smoothing = true;
					bitmaps[arData.masks[i].id] = Bitmap(mask).bitmapData;
				}
				else
				{
					var scale:Number = Math.max(shellApi.viewportWidth / mask.width, shellApi.viewportHeight / mask.height) / 5;
					
					if(PlatformUtils.isMobileOS || scale < 1)
						scale = 1;
					
					var wrapper:BitmapWrapper = convertToBitmapSprite(mask,null, false,scale);
					
					wrapper.bitmap.smoothing = true;
					bitmaps[arData.masks[i].id] = wrapper.data;
					mask = wrapper.sprite;
				}
				maskContainer.addChild(mask);
				
				mask.x = rect.x + rect.width / 2;
				mask.y = rect.y + (i+1) * rect.height / (arData.masks.length + 1);
				
				var uiScale:Number = Math.min(rect.width / mask.width, (rect.height / (arData.masks.length + 1))/mask.height);
				mask.scaleX = mask.scaleY = uiScale;
				
				var position:ArPositionData = assetData.position;
				mask.x += position.offset.x * uiScale;
				mask.y += position.offset.y * uiScale;
				mask.scaleY *= position.flipped?-1:1;
				mask.rotation = position.rotation;
				
				entity = EntityUtils.createSpatialEntity(this, mask, maskContainer);
				
				entity.add(new Id(arData.masks[i].id));
				interaction = InteractionCreator.addToEntity(entity, [InteractionCreator.CLICK]);
				// I would like to set up a system so we can swap mask assigned by a system that determines which node to track
				interaction.click.add(swapMasks);
				ToolTipCreator.addToEntity(entity);
				if(i == 0)
				{
					arEffect.focusChanged.addOnce(setInitialMask);
				}
			}
		}
		
		private function setInitialMask(faceInFocus:int):void
		{
			var entity:Entity = getEntityById(arData.masks[0].id);
			var interaction:Interaction = entity.get(Interaction);
			interaction.click.dispatch(entity);
		}
		
		private function swapMasks(entity:Entity):void
		{
			var id:String =	Id(entity.get(Id)).id;
			var asset:ArAsset = arData.getMaskById(id);
			var position:ArPositionData = asset.position;
			
			var currentId:String;// store the id of the asset being stored in the current node placement
			
			var index:int;
			
			// if there are no faces detected return
			if(arEffect.faceInFocus == -1)
				return;
			
			var face:FacialLandMarks = arEffect.baseNodes[arEffect.faceInFocus];
			
			var mask:Entity = getEntityById(position.node+"_"+arEffect.faceInFocus);
			if(mask)
			{
				currentId = ArAssetComponent(mask.get(ArAssetComponent)).asset.id;
				index = face.masksApplied.indexOf(currentId);
				if(index != -1)
					face.masksApplied.splice(index, 1);
				removeEntity(mask);
				IAdManager(shellApi.adManager).track(campaign,"MaskRemoved",currentId);
			}
			
			var disp:DisplayObject = asset.asset;
			// if the current asset is the same as the new asset, just remove and don't re add
			if(disp == null || currentId == id)
				return;
			
			face.masksApplied.push(id);
			
			IAdManager(shellApi.adManager).track(campaign,"MaskApplied",id);
			
			var sequence:BitmapSequence;
			
			// if this asset is a timeline create a bitmap sequence for it
			if(disp is MovieClip && MovieClip(disp).totalFrames > 1)
			{
				sequence = BitmapTimelineCreator.createSequence(disp as MovieClip);
			}
			
			var landMark:FacialLandMarkData = face.GetLandMarkById(position.node);
			// if a sequence was created, create an entity based on timelines
			if(sequence)
			{
				landMark.sprite.addChild(disp);
				mask = BitmapTimelineCreator.createBitmapTimeline(disp as MovieClip,true,true, sequence);
				addEntity(mask);
				
				Timeline(mask.get(Timeline)).play();
				if(asset.emotes.indexOf(ArEffectSysytem.CLICK) != -1)
				{
					InteractionCreator.addToEntity(mask,[ArEffectSysytem.CLICK]).click.add(playClickAnimation);
					ToolTipCreator.addToEntity(mask);
				}
			}
			else//just create a static image
			{
				var sprite:Sprite = BitmapUtils.createBitmapSprite(disp,1, null,true, 0, bitmaps[id]);
				mask = EntityUtils.createSpatialEntity(this, sprite, landMark.sprite);
			}
			// add an id based on the node its following and the face that it belongs to
			mask.add(new Id(asset.position.node+"_"+arEffect.faceInFocus));
		//	mask.add(new ArAssetComponent(asset, faces[arEffect.faceInFocus]));
			// position rotate and scale based on the data for the asset
			var spatial:Spatial = mask.get(Spatial);
			spatial.scale = position.scale;
			spatial.rotation = position.rotation;
			spatial.x = position.offset.x * position.scale;
			spatial.y = position.offset.y * position.scale;
			var direction:int = position.flipped?-1:1;
			spatial.scaleY = Math.abs(spatial.scaleY) * direction;
		}
		
		private function playClickAnimation(entity:Entity):void
		{
			Timeline(entity.get(Timeline)).gotoAndPlay(ArEffectSysytem.CLICK);
			var asset:ArAssetComponent = entity.get(ArAssetComponent);
			if(asset.lastEmote != null)
				asset.emoteStates[asset.lastEmote] = false;
			asset.lastEmote = ArEffectSysytem.CLICK;
			asset.emoteStates[ArEffectSysytem.CLICK] = true;
		}
		
		private function setUpAr():void
		{
			trace("set up AR");
			var sprite:Sprite = new Sprite();
			scene.addChild(sprite);
			
			sprite.x = -shellApi.viewportWidth/2;
			sprite.y = -shellApi.viewportHeight/2;
			
			addSystem(new ArEffectSysytem());
			
			var arEntity:Entity = EntityUtils.createSpatialEntity(this, sprite);
			arEffect = new ArEffect(2, arData.landMarkers);
			arEffect.cameraFound.add(OnArReady);
			arEntity.add(arEffect);
		}
		
		private function OnArReady(ready:Boolean):void
		{
			trace("AR READY: " + ready);
			
			if(!isReady)
			{
				super.loaded();
			}
			if(ready)
			{
				setUpMasks();
			}
			else
			{
				if(cameraPermissionsConfirmed)
				{
					close();
					return;
				}
				cameraPermissionsConfirmed = true;
				var camera:Camera = arEffect.cam.camera;
				var popup:ConfirmationDialogBox = addChildGroup(new ConfirmationDialogBox(camera == null? 1:2, "Can not create AR without camera")) as ConfirmationDialogBox;
				popup.configData(null,null,null,"Retry");
				popup.init(content["popupContainer"]);
				popup.confirmClicked.add(close);
				popup.cancelClicked.add(camera.requestPermission);
			}
		}
		
		private function closeButtonClicked(entity:Entity):void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH+CLICK_EXIT);
			IAdManager(shellApi.adManager).track(campaign, "PhotoBoothClosed");
			close();
		}
		
		private function savePhoto(e:MouseEvent):void
		{
			// don't allow the save button to be triggered multiple times while dialog box is being displayed
			if(getGroupById(ConfirmationDialogBox.GROUP_ID))
				return;
			
			if(arEffect.faceInFocus == -1)
			{
				IAdManager(shellApi.adManager).track(campaign, "ARSaved", "OutOfFocus");
			}
			else
			{
				var masks:Array = [];
				for(var i:int = 0; i< arEffect.baseNodes.length; i++)
				{
					var face:FacialLandMarks = arEffect.baseNodes[i];
					masks = masks.concat(face.masksApplied);
				}
				if(masks.length == 0)
				{
					IAdManager(shellApi.adManager).track(campaign, "ARSaved", "NoMasksApplied");
				}
				else
				{
					IAdManager(shellApi.adManager).track(campaign, "ARSaved", masks.toString());
				}
			}
			
			
			AudioUtils.play(this, SoundManager.EFFECTS_PATH+CLICK_SAVE);
			
			convertSceneToBitmap();
			
			if(PlatformUtils.isMobileOS)
			{
				SceneUtil.lockInput(this);
				shellApi.saveBitmapDataToCameraRoll(picData,"PoptropicaPhoto" + (++photoNumber) + ".png",savedToCameraRoll, Command.create(savedToCameraRoll, false));
			}
			else
			{
				var file:FileReference = new FileReference();
				file.save(PNGEncoder.encode(picData ),"PoptropicaPhoto" + (++photoNumber) + ".png");
				file.addEventListener(Event.COMPLETE, saveComplete);
			}
		}
		
		private function convertSceneToBitmap():void
		{
			var rect:Rectangle = border.getBounds(border.parent);
			rect.height-=1;//always seems to get an extra pixel for some reason
			
			// remove feed back
			arEffect.draw.imageContainer.alpha = 0;
			
			var caption:CaptionData = new CaptionData("I made this and more at www.poptropica.com","CreativeBlock BB");
			
			var image:MovieClip = scene.parent as MovieClip;
			
			image.addChild(caption);
			caption.x = rect.left + rect.width * caption.alignX;
			caption.y = rect.top + rect.height * caption.alignY;
			
			var quality:Number = 1;
			
			picData = createBitmapData(image,quality, rect);
			image.removeChild(caption);
			// re apply feed back
			arEffect.draw.imageContainer.alpha = 1;
		}
		
		protected function saveComplete(...args):void
		{
			if(DataUtils.validString(arData.adCardSaved))
			{
				if(!shellApi.checkHasItem(arData.adCardSaved, CardGroup.CUSTOM))
					itemGroup.showAndGetItem(arData.adCardSaved, CardGroup.CUSTOM, null, screen);
			}
		}
		
		private function savedToCameraRoll(success:Boolean = true):void
		{
			var message:String = success? "Your photo has been added to your camera roll.": "Your photo failed to save to your camera roll.";
			SceneUtil.lockInput(this, false);
			var popup:ConfirmationDialogBox = addChildGroup(new ConfirmationDialogBox(1,message)) as ConfirmationDialogBox;
			popup.init(content["popupContainer"]);
			popup.confirmClicked.add(saveComplete);
		}
	}
}