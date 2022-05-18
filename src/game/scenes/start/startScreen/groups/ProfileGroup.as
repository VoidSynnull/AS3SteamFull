package game.scenes.start.startScreen.groups
{
	import com.greensock.TweenMax;
	import com.greensock.easing.Elastic;
	import com.poptropica.Assert;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.components.Tween;
	import engine.group.DisplayGroup;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.motion.WaveMotion;
	import game.components.ui.Button;
	import game.creators.entity.character.CharacterCreator;
	import game.creators.ui.ButtonCreator;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.data.character.LookConverter;
	import game.data.character.LookData;
	import game.data.character.PlayerLook;
	import game.data.profile.ProfileData;
	import game.data.sound.SoundModifier;
	import game.scene.template.CharacterGroup;
	import game.systems.entity.EyeSystem;
	import game.systems.motion.WaveMotionSystem;
	import game.util.AudioUtils;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	
	import org.osflash.signals.Signal;
	
	public class ProfileGroup extends DisplayGroup
	{
		private var bitmaps:Vector.<Bitmap> = new Vector.<Bitmap>();
		
		private var deleteProfile:Boolean;
		
		private var display:DisplayObjectContainer;
		
		private var PROFILE_OFFSET_X:int = 157;
		
		private var converter:LookConverter = new LookConverter();
		private var dummy:Entity;
		
		private var warning:Entity;
		private var warningButton:Entity;
		
		private var profiles:Array = new Array();
		private var profileCount:int = 0;
		
		public var clicked:Signal = new Signal(ProfileData);
		
		private var tween:Tween;
		
		public function ProfileGroup(container:DisplayObjectContainer=null, deleteProfile:Boolean = false)
		{
			super(container);
			
			this.id = "profileGroup";
			this.groupPrefix = "scenes/start/startScreen/groups/profileGroup/";
			
			this.deleteProfile = deleteProfile;
		}
		
		override public function init(container:DisplayObjectContainer=null):void
		{
			this.load();
		}
		
		override public function destroy():void
		{
			//Destroy stuff here.
			this.container.removeChild(this.display);
			
			for each(var bitmap:Bitmap in this.bitmaps)
			{
				bitmap.bitmapData.dispose();
				bitmap.bitmapData = null;
			}
			this.bitmaps = null;
			
			super.destroy();
		}
		
		override public function load():void
		{
			this.loadFiles(["profile.swf"], false, true, this.loaded);
		}
		
		override public function loaded():void
		{
			super.loaded();
			
			if(!this.getSystem(WaveMotionSystem)) this.addSystem(new WaveMotionSystem());
			
			this.display = this.getAsset("profile.swf", true);
			this.container.addChild(this.display);
			
			//this.display.y += 50;
			
			this.tween = this.getGroupEntityComponent(Tween);
			
			this.setupOverwriteWarning();
			
			this.setupProfiles();
		}
		
		private function setupOverwriteWarning():void
		{
			var clip:MovieClip = this.display["warning"];
			if(this.deleteProfile)
			{
				this.warning = EntityUtils.createSpatialEntity(this, clip);
				
				this.warningButton = ButtonCreator.createButtonEntity(clip["close"], this, closeWarning, null, null, null, true, true, 2);
				
				var interaction:Interaction = this.warningButton.get(Interaction);
				interaction.over.add(onOver);
				interaction.lock = true;
			}
			else
			{
				this.display.removeChild(clip);
			}
		}
		
		private function closeWarning(entity:Entity):void
		{
			this.shellApi.track("UserProfileDeleted");
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "ui_button_click.mp3", 1, false, SoundModifier.EFFECTS);
			
			this.removeEntity(entity);
			this.removeEntity(this.warning);
			
			var i:int = this.profiles.length - 1;
			for(i; i > -1; i--)
			{
				entity = this.getEntityById("profile" + i);
				entity.get(Interaction).lock = false;
			}
		}
		
		private function setupProfiles():void
		{
			for each(var profileData:ProfileData in this.shellApi.profileManager.profiles)
			{
				trace(profileData.login + " : " + profileData.avatarName + " : " + profileData.profileComplete)
				if(profileData.profileComplete)
				{
					this.profiles.push(profileData);
				}
			}
			
			PROFILE_OFFSET_X = 300 - (143 * ((this.profiles.length - 1) / 5));
			
			if(this.profiles.length == 1)
			{
				this.clicked.dispatch(this.profiles[0]);
				this.parent.removeGroup(this);
			}
			else
			{
				var step:String = "sortProfiles";
				
				try
				{
					this.profiles.sort(this.sortProfiles);
					
					step = "setupCharacterGroup";
					
					var characterGroup:CharacterGroup = this.getGroupById(CharacterGroup.GROUP_ID) as CharacterGroup;
					if(!characterGroup)
					{
						characterGroup = new CharacterGroup();
						characterGroup.setupGroup(this);
					}
					
					step = "createDummy";
					
					this.dummy = characterGroup.createDummy("dummy", new LookData(), CharUtils.DIRECTION_RIGHT, "", this.display, this, dummyLoaded, true, .72, CharacterCreator.TYPE_PORTRAIT);
					this.dummy.get(Display).alpha = 0;
				}
				catch(e:Error)
				{
					Assert.error("ProfileSelectionApplyLookError", step);
				}
			}
		}
		
		/**
		 * Currently, profiles being taken from the Profile Manager dictionary are being sorted by the numerical suffix
		 * of their login name. Might want to have another variable that specifies the order in which they should appear.
		 */
		private function sortProfiles(data1:ProfileData, data2:ProfileData):int
		{
			var index1:int = int(data1.login.replace("default", ""));
			var index2:int = int(data2.login.replace("default", ""));
			
			return index1 < index2 ? -1 : 1;
		}
		
		/**
		 * Once the base dummy is loaded, apply profile looks to him, then bitmap what he looks like to each individual
		 * profile button. Less costly than loading a separate character for each profile look. Ick.
		 */
		private function dummyLoaded(dummy:Entity):void
		{
			this.dummy.get(Spatial).y = -30;
			this.createProfileButton();
		}
		
		private function createProfileButton():void
		{
			this.loadFile("profileButton.swf", this.buttonLoaded);
		}
		
		private function buttonLoaded(clip:MovieClip):void
		{
			var step:String = "getProfileData";
			
			try
			{
				var profileData:ProfileData = this.profiles[this.profileCount];
				
				step = "addButton";
				
				clip.y = this.shellApi.viewportHeight;
				this.display.addChildAt(clip, 0);
				
				step = "addNameLabel";
				
				var textField:TextField = new TextField();
				textField.text = profileData.avatarFirstName + "\n" + profileData.avatarLastName;
				textField.setTextFormat(new TextFormat("CreativeBlock BB", 30, 0xFFFFFF, null, null, null, null, null, TextFormatAlign.CENTER));
				textField.x 			= -140;
				textField.y 			= 100;
				textField.width 		= 280;
				textField.embedFonts 	= true;
				textField.autoSize = TextFieldAutoSize.CENTER;
				
				clip.addChild(textField);
				clip.scaleX = clip.scaleY = 1 - (0.4 * ((this.profiles.length - 1) / 5));
			
				step = "createButton";
				
				var entity:Entity = ButtonCreator.createButtonEntity(clip, this, onClick, null, null, null, false, false);
				
				entity.get(Button).value = this.profiles[this.profileCount];
				entity.add(new Id("profile" + (this.profileCount)));
				
				clip.mouseChildren = true;
				clip.mouseEnabled = false;
				
				addWaveMotion(entity, this.profileCount);
				
				step = "addTween";
				
				var offsetX:Number = 0;
				var numProfiles:int = this.profiles.length;
				if(numProfiles % 2) numProfiles--;
				else offsetX = PROFILE_OFFSET_X / 2;
				
				var spatial:Spatial = entity.get(Spatial);
				spatial.x = (this.profileCount - (numProfiles / 2)) * PROFILE_OFFSET_X + offsetX;
				
				var tweenMax:TweenMax = this.tween.to(spatial, 1, {y:0, ease:Elastic.easeOut, easeParams:[0, 0.5]});
				tweenMax.delay = this.profileCount * 0.05;
				
				step = "addInteraction";
				
				var interaction:Interaction = entity.get(Interaction);
				interaction.over.add(onOver);
				
				//Lock the interactions until the warning has been clicked first.
				if(this.deleteProfile) 
				{
					interaction.lock = true;
				}
				
				if(++this.profileCount < this.profiles.length)
				{
					step = "createProfileButton";
					this.createProfileButton();
				}
				else
				{
					if(this.deleteProfile)
					{
						step = "showWarning";
						this.warningButton.get(Interaction).lock = false;
					}
					
					this.profileCount = 0;
					
					// we add the avatars AFTER the buttons have been loaded, so that if an issue occurs we can still pick a profile.
					addAvatars();
				}
			}
			catch(e:Error)
			{
				//Assert.error("ProfileSelectionApplyLookError", step);
			}
		}
		
		private function addAvatars():void
		{
			if(this.profileCount < this.profiles.length)
			{
				var entity:Entity = super.getEntityById("profile" + this.profileCount);
				addAvatar(entity, this.profiles[this.profileCount]);
				this.profileCount++;
			}
			else
			{
				this.removeEntity(this.dummy);
				this.dummy 		= null;
				this.converter 	= null;
			}
		}
		
		private function addAvatar(buttonEntity:Entity, profileData:ProfileData):void
		{
			try
			{
				if(!profileData.look) profileData.look = new PlayerLook();
				
				var step:String = "convertLook";
				
				var lookData:LookData = this.converter.lookDataFromPlayerLook(profileData.look);
				lookData.fillWithEmpty();
				
				step = "applyLook";
				
				SkinUtils.applyLook(this.dummy, lookData, true, Command.create(this.waitForPartUpdate, buttonEntity));
			}
			catch(e:Error)
			{
				Assert.error("ProfileSelectionAddAvatarError", step);
			}
		}
		
		private function waitForPartUpdate(dummy:Entity, buttonEntity:Entity):void
		{
			SceneUtil.addTimedEvent(this, new TimedEvent(0.1, 1, Command.create(lookLoaded, dummy, buttonEntity)));
		}
		
		private function lookLoaded(dummy:Entity, buttonEntity:Entity):void
		{
			var step:String = "setEyes";
			
			//Applying new LookData resets the eyes. Have to do this each time.
			try
			{
				var buttonDisplay:Display = buttonEntity.get(Display);
				var clip:MovieClip = buttonDisplay.displayObject
				
				SkinUtils.setEyeStates( this.dummy, SkinUtils.getSkinPart( dummy, SkinUtils.EYE_STATE ).permanent + EyeSystem.STILL );
				
				step = "createBitmap";
				
				var display:Display = this.dummy.get(Display);
				var bitmap:Bitmap = BitmapUtils.createBitmap(display.displayObject, 2);
				DisplayObjectContainer(clip["empty"]).addChild(bitmap);
				this.bitmaps.push(bitmap);
				
				// fade in
				bitmap.alpha = 0;
				this.tween.to(bitmap, .5, {alpha : 1});
				
				addAvatars();
			}
			catch(e:Error)
			{
				//Assert.error("ProfileSelectionSetupLookButtonError", step);
			}
		}
		
		private function onOver(entity:Entity):void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "ui_roll_over.mp3", 1, false, SoundModifier.EFFECTS);
		}
		
		private function onClick(entity:Entity):void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "ui_button_click.mp3", 1, false, SoundModifier.EFFECTS);
			
			var profile:ProfileData = entity.get(Button).value;
			
			this.clicked.dispatch(profile);
			
			this.close(entity);
		}
		
		public function close(entity:Entity):void
		{
			var object:Object = {y:this.shellApi.viewportHeight, ease:Elastic.easeIn, easeParams:[0, 0.5]};
			var tweenMax:TweenMax;
			var delay:int = 0;
			
			for(var i:int = 0; i < this.profileCount; i++)
			{
				var profileEntity:Entity = this.getEntityById("profile" + i);
				
				if(!entity || (profileEntity != entity))
				{
					tweenMax = this.tween.to(profileEntity.get(Spatial), 0.7, object);
					tweenMax.delay = delay++ * 0.05;
				}
			}
			
			SceneUtil.addTimedEvent(this, new TimedEvent(0.7, 1, Command.create(this.parent.removeGroup, this)));
		}
		
		private function addWaveMotion(entity:Entity, i:int):void
		{
			entity.add(new SpatialAddition());
			
			var wave:WaveMotion = new WaveMotion();
			entity.add(wave);
			
			wave.data.push(new WaveMotionData("y", 10, 0.05, "sin", i * 1));
		}
	}
}