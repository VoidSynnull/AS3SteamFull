package game.data.print
{
	import com.poptropica.AppConfig;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.geom.Rectangle;
	import flash.printing.PrintJob;
	import flash.printing.PrintJobOptions;
	
	import ash.core.Entity;
	
	import engine.ShellApi;
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.group.DisplayGroup;
	import engine.group.Scene;
	
	import game.components.entity.Sleep;
	import game.components.entity.character.animation.AnimationControl;
	import game.components.entity.character.part.eye.Eyes;
	import game.components.timeline.Timeline;
	import game.creators.entity.character.CharacterCreator;
	import game.scene.template.CharacterGroup;
	import game.ui.elements.ConfirmationDialogBox;
	import game.util.CharUtils;
	import game.util.ClassUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
		
	/*****************************************************
	 * Print avatar poster (displays user's avatar on jpeg or swf before printing)
	 * Using bitmap data (jpg) fails on mobile, so always use a swf for mobile
	 * The bitmap can reside inside the swf and that works okay
	 * 
	 * <p>Date : 2/2/18</p>
	 * 
	 * @author	Rick Hocker
	 * ***************************************************/
	
	public class PrintAvatarPoster
	{				 		
		// NOTE :: Probably want to look into leveraging the Photo.as popup class.
		
		/**
		 * Print avatar poster (displays user's avatar on poster before printing)
		 * @param	path		path to jpeg or swf on server (i.e. posters/poster.swf)
		 * @param	x			x pos of avatar on poster
		 * @param	y			y pos of avatar on poster
		 * @param	scale		scale of avatar on poster
		 * @param	rotation	rotation of avatar on poster
		 * @param	pose		avatar pose
		 * @param	frame		avatar pose frame
		 */
		public function PrintAvatarPoster(shellApi:ShellApi, path:String, x:Number, y:Number , xscale:Number, yscale:Number, rotation:Number, pose:String = null, frame:uint = 0, eyeState=null, eyesAngle:Number = 0, mouth:String=null):void
		{
			trace("PrintPoster: path: " + path);
			
			var arr:Array = path.split("/");
			fileName = arr[arr.length-1];
			var index:int = fileName.indexOf(".");
			fileName = fileName.substr(0, index);
			
			this.shellApi = shellApi;
			if (isNaN(x))
			{
				hasAvatar = false;
			}
			else
			{
				// remember avatar position
				xPos = x;
				yPos = y;
				avatarScaleX = xscale;
				avatarScaleY = yscale;
				avatarRotation = rotation;
				avatarPose = pose;
				avatarFrame = frame;
				eyesState = eyeState;
				eyesRotation = eyesAngle;
				mouthFrame = mouth;
			}
			
			// check if swf
			isSwf = (path.indexOf("swf") != -1);
			
			var stage:Stage = shellApi.screenManager.sceneContainer.stage;
			// create clip for poster
			container = MovieClip(stage.addChild(new MovieClip()));
			posterHolder = Sprite(container.addChild(new Sprite()));
			poster = Sprite(posterHolder.addChild(new Sprite()));
			
			// load jpeg or swf
			shellApi.loadFile(shellApi.assetPrefix + path, onLoadPoster);
		}
		
		private function onLoadPoster(asset:DisplayObject):void
		{
			trace("PrintPoster: load success : " + asset);
			
			if ((isSwf) && (shellApi.profileManager.active.avatarFirstName))
			{
				if (MovieClip(asset)["firstName"] != null)
					MovieClip(asset)["firstName"].text = shellApi.profileManager.active.avatarFirstName;
				if (MovieClip(asset)["lastName"] != null)
					MovieClip(asset)["lastName"].text = shellApi.profileManager.active.avatarLastName;
			}
			
			// center jpeg or swf on poster for web only
			poster.addChild(asset);
			if (!AppConfig.mobile)
			{
				poster.x = -asset.width / 2;
				poster.y = -asset.height / 2;
			}
			
			// if testing then center poster
			if (testing)
			{
				container.x = 480 - xPos/3;
				container.y = 320 - yPos/3;
			}
			else
			{
				// if not testing then move offscreen
				container.x = -3 * asset.width;
				container.y = -3 * asset.height;
			}
			
			if (hasAvatar)
			{
				trace("Print Poster: with avatar");
				// load avatar now
				// use popup
				var charGroup:CharacterGroup = new CharacterGroup();
				group = new DisplayGroup(MovieClip(asset));
				shellApi.sceneManager.currentScene.addChildGroup(group);
				charGroup.setupGroup(group, MovieClip(asset));
				avatar = charGroup.createNpcPlayer( onLoadAvatar, null, null, CharacterCreator.TYPE_PORTRAIT);	// NOTE :: This should be a portrait
				
				// set up foreground, if any
				if (asset["foreground"])
				{
					trace("PrintPoster: move foreground");
					var avatarClip:MovieClip = avatar.get(Display).displayObject;
					avatarClip.parent.swapChildren(avatarClip, asset["foreground"]);
				}
			}
			else
			{
				trace("Print Poster: no avatar");
				sentToPrinterOrRoll();
			}
		}
		
		private function onLoadAvatar(char:Entity):void
		{
			trace("PrintPoster: avatar load success: pos: " + xPos + "," + yPos);
			trace("PrintPoster: avatar size: " + avatar.get(Spatial).width + "," + avatar.get(Spatial).height);
			avatar.get(Spatial).x = xPos;
			avatar.get(Spatial).y = yPos;
			avatar.get(Spatial).rotation = avatarRotation;
			// NOTE :: Should set scale before laoding character for better bitmap quality
			avatar.get(Spatial).scaleX = avatarScaleX * 0.36;
			avatar.get(Spatial).scaleY = avatarScaleY * 0.36;
			if (avatarPose)
			{
				trace("PrintPoster: avatar pose: " + avatarPose + " at frame: " + avatarFrame);
				var anim:Class = ClassUtils.getClassByName("game.data.animation.entity.character." + avatarPose);
				CharUtils.setAnim(avatar,anim);
				var timeline:Timeline = CharUtils.getTimeline(avatar);
				timeline.gotoAndStop(avatarFrame);
			}
			// need eyeState and rotation
			if (eyesState)
			{
				var eyes:Eyes = SkinUtils.getSkinPartEntity( avatar, SkinUtils.EYES ).get( Eyes );
				SkinUtils.setEyeStates( avatar, eyesState, eyesRotation);
				eyes.locked = true;
			}
			if (mouthFrame)
				SkinUtils.setSkinPart( avatar, SkinUtils.MOUTH, mouthFrame, true);
			avatar.get(Sleep).ignoreOffscreenSleep = true;
			avatar.get(Sleep).sleeping = false;
			avatar.get(Display).displayObject.printPoster = true;
			avatar.get(AnimationControl).stop();
			// add delay
			trace("Print Poster: has avatar");
			SceneUtil.delay(group, printDelay, sentToPrinterOrRoll);
		}
		
		private function sentToPrinterOrRoll():void
		{
			// if mobile, send to camera roll
			if (AppConfig.mobile)
			{
				trace("Print Poster: begin save to camera roll");
				// set clipping rect to standard size (this fixes wrong movieClip dimensions when masks are used)
				var clipRect:Rectangle = new Rectangle(0, 0, container.width, container.height);
				// save to camera roll (nothing happens in FlashBuilder)
				shellApi.saveMovieClipToCameraRoll(container, clipRect, fileName, onSaveSuccess, onSaveFailure);
			}
			else
			{
				var my_pj:PrintJob = new PrintJob();
				trace("PrintPoster: printing printjob: " + my_pj);
				var started:Boolean = false;
				try {
					my_pj.start();
					started = true;
				}
				catch (e:Error) {
					trace("PrintPoster: can't start printjob");
				}
				if (started)
				{
					var vWidth:Number, vHeight:Number;
					var vRotate:Boolean;
					
					var maxPrint:Number = Math.max(my_pj.pageWidth, my_pj.pageHeight);
					
					// if poster is horizontal
					if (container.width > container.height)
					{
						// if landscape then don't rotate
						if (my_pj.orientation == "landscape")
							vRotate = false;
						else
							vRotate = true;
					}
					else
					{
						// if poster is vertical
						// if landscape then rotate
						if (my_pj.orientation == "landscape")
							vRotate = true;
						else
							vRotate = false;
					}
					
					// draw white box behind
					container.graphics.beginFill(0xFFFFFF);
					container.graphics.drawRect(-maxPrint, -maxPrint, 2 * maxPrint, 2 * maxPrint);
					container.graphics.endFill();
					
					if (vRotate)
					{
						vWidth = poster.height;
						vHeight = poster.width;
						posterHolder.rotation = -90;
					}
					else
					{
						vWidth = poster.width;
						vHeight = poster.height;
					}
					
					// get scale that will fit page
					var scaleDownW:Number = my_pj.pageWidth / vWidth;
					var scaleDownH:Number = my_pj.pageHeight / vHeight;
					var scaleDown:Number = Math.min(scaleDownW, scaleDownH);
					
					// scale poster holder
					posterHolder.scaleX = posterHolder.scaleY = scaleDown;
					
					// set printing bounds
					var xMin:Number = -my_pj.pageWidth/2;
					var xMax:Number = my_pj.pageWidth/2;
					var yMin:Number = -my_pj.pageHeight/2;
					var yMax:Number = my_pj.pageHeight / 2;
					
					trace("PrintPoster: orientation: " + my_pj.orientation);
					trace("PrintPoster: scaling: " + scaleDown);
					trace("PrintPoster: rotate: " + vRotate);
					trace("PrintPoster: print dimensions: " + my_pj.pageWidth + "," + my_pj.pageHeight);
					trace("PrintPoster: image dimensions: " + vWidth * scaleDown + "," + vHeight * scaleDown);
					trace("PrintPoster: printing page: " + xMin + "," + xMax + "," + yMin + "," + yMax);
					
					// print
					var pageAdded:Boolean = false;
					var options:PrintJobOptions = new PrintJobOptions(true);
					var printRect:Rectangle = new Rectangle(xMin, yMin, xMax - xMin, yMax - yMin);
					try {
						my_pj.addPage(container, printRect, options);
						pageAdded = true;
					}
					catch(e:Error) {
						// handle error
						trace("PrintPoster: error adding page");
					}
					if (pageAdded) {
						my_pj.send();
					}
				}
				cleanUp();
			}
		}
		
		private function cleanUp():void
		{
			trace("PrintPoster: done printing");
			if (!testing)
			{
				// remove poster group
				shellApi.sceneManager.currentScene.removeGroup(group);
				// remove holders
				posterHolder.removeChildAt(0);
				container.removeChildAt(0);
				// remove last chlld of stage
				var stage:Stage = shellApi.screenManager.sceneContainer.stage;
				stage.removeChildAt(stage.numChildren-1);
			}
		}
						
		/**
		 * When saved to camera roll successfully 
		 */
		private function onSaveSuccess():void
		{
			onSave("Your image has been added to your camera roll.");
		}
		
		/**
		 * When failed to save to camera roll
		 */
		private function onSaveFailure():void
		{
			onSave("Your image failed to save to your camera roll.");
		}
		
		/**
		 * When saving to camera roll is complete, then cleanup and show dialog
		 * @param message
		 */
		private function onSave(message:String):void
		{
			var scene:Scene = shellApi.sceneManager.currentScene;
			
			cleanUp();
			
			// display dialog box
			var dialogBox:ConfirmationDialogBox = new ConfirmationDialogBox(1, message);
			dialogBox.id = "PrintPoster";
			
			dialogBox = ConfirmationDialogBox(scene.addChildGroup(dialogBox));
			dialogBox.darkenBackground = true;
			dialogBox.pauseParent = false;
			dialogBox.init(Scene(scene).overlayContainer);			
		}
		
		private var fileName:String;
		private var shellApi:ShellApi;
		private var isSwf:Boolean;
		private var group:DisplayGroup;
		private var avatar:Entity;
		private var container:MovieClip;
		private var posterHolder:Sprite;
		private var poster:Sprite;
		private var xPos:Number;
		private var yPos:Number;
		private var avatarScaleX:Number;
		private var avatarScaleY:Number;
		private var avatarRotation:Number;
		private var avatarPose:String;
		private var avatarFrame:int;
		private var eyesState:String;
		private var eyesRotation:Number;
		private var mouthFrame:String;
		private var printDelay:Number = 1.0;
		private var testing:Boolean = false;
		private var hasAvatar:Boolean = true;
	}
}