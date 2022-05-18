package game.scenes.shrink.bedroomShrunk01
{
	import com.greensock.easing.Linear;
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.collider.PlatformCollider;
	import game.components.entity.collider.RectangularCollider;
	import game.components.entity.collider.SceneObjectCollider;
	import game.components.hit.EntityIdList;
	import game.components.hit.HitTest;
	import game.components.hit.Platform;
	import game.components.hit.Wall;
	import game.components.motion.FollowTarget;
	import game.components.motion.Mass;
	import game.components.motion.TargetEntity;
	import game.components.motion.Threshold;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.motion.SceneObjectCreator;
	import game.creators.scene.HitCreator;
	import game.creators.ui.KeyboardCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Place;
	import game.data.item.UseItemData;
	import game.data.ui.ToolTipType;
	import game.scene.template.AudioGroup;
	import game.scene.template.ItemGroup;
	import game.scenes.backlot.extSoundStage2.Swing;
	import game.scenes.backlot.extSoundStage2.SwingSystem;
	import game.scenes.shrink.ShrinkEvents;
	import game.scenes.shrink.bedroomShrunk01.LampJointSystem.JointedLamp;
	import game.scenes.shrink.bedroomShrunk01.LampJointSystem.JointedLampSystem;
	import game.scenes.shrink.bedroomShrunk01.Popups.BlankPaperPopup;
	import game.scenes.shrink.bedroomShrunk01.Popups.DiaryPagePopup;
	import game.scenes.shrink.shared.Systems.PressSystem.Press;
	import game.scenes.shrink.shared.Systems.PressSystem.PressSystem;
	import game.scenes.shrink.shared.Systems.TipSystem.Tip;
	import game.scenes.shrink.shared.Systems.WalkToTurnDialSystem.WalkToTurnDial;
	import game.scenes.shrink.shared.Systems.WalkToTurnDialSystem.WalkToTurnDialSystem;
	import game.scenes.shrink.shared.groups.ShrinkScene;
	import game.scenes.shrink.shared.popups.Jump;
	import game.scenes.shrink.shared.popups.MicroscopeMessage;
	import game.scenes.shrink.shared.popups.Ramp;
	import game.systems.SystemPriorities;
	import game.systems.hit.SceneObjectHitRectSystem;
	import game.systems.motion.SceneObjectMotionSystem;
	import game.systems.motion.ThresholdSystem;
	import game.ui.keyboard.KeyboardPopup;
	import game.ui.popup.OneShotPopup;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.TextUtils;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;

	public class BedroomShrunk01 extends ShrinkScene
	{
		public function BedroomShrunk01()
		{
			//showHits = true;
			super();
		}

		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.groupPrefix = "scenes/shrink/bedroomShrunk01/";

			super.init(container);
		}

		private var shrink:ShrinkEvents;

		private const PASSWORD:String = "m4r13 cur13";
		private const MARIE_CURIE:String = "marie curie";

		private var _attemptLogin:Boolean = false;
		private var _targetEntity:TargetEntity;

		private var keyboard:KeyboardPopup;
		private var email:OneShotPopup;
		private var diary:DiaryPagePopup;
		private var blankPaper:BlankPaperPopup;

		private var loginText:TextField;
		private var sampleText:MovieClip;

		private var carInfo:Array;

		override protected function addBaseSystems():void
		{
			super.addBaseSystems();

			addSystem(new SceneObjectHitRectSystem());
			addSystem(new SceneObjectMotionSystem(), SystemPriorities.moveComplete);
			addSystem(new ThresholdSystem());
			addSystem(new JointedLampSystem());
			addSystem(new PressSystem());
			addSystem(new SwingSystem(player));
			addSystem(new WalkToTurnDialSystem());
		}

		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			shrink = events as ShrinkEvents;

			shellApi.eventTriggered.add(onEventTriggered);

			player.add(new SceneObjectCollider());
			player.add(new RectangularCollider());
			player.add(new Mass(100));

			_targetEntity = player.get( TargetEntity );

			setUpUseItems();
			setUpCarBlock(false);
			setUpBooks();
			setUpDial();
			setUpEyes();
			setUpNecklace();
			setUpMessage();
			setUpComputer();
			setUpDiary();
			setUpPaper();
			setUpLamp();
		}

		private function setUpUseItems():void
		{
			_hitContainer[ "blankPaper" ].y -= 20;
			useableItems[shrink.DIARY_KEY] = new UseItemData(useDiaryKey,true, shrink.NO_POINT+shrink.DIARY_KEY, shrink.DIARY_UNLOCKED, "already_open",true, "diaryLock", 300);
			useableItems[shrink.THUMB_DRIVE] = new UseItemData(useThumbDrive, true, shrink.NO_POINT+shrink.THUMB_DRIVE, shrink.BACKED_UP_THUMB_DRIVE, "already_copied", true, "thumbDrive", 300);
			useableItems[shrink.BLANK_PAPER] = new UseItemData(useBlankPaper, true, shrink.NO_POINT+shrink.BLANK_PAPER, shrink.DONT_KNOW_WHAT_TO_DO_WITH_PAPER_YET, "wat_do_do", true, "blankPaper", 300);
			useableItems[shrink.TORN_PAGE] = new UseItemData(useTornPage, true, shrink.NO_POINT+shrink.TORN_PAGE, shrink.DIARY_RESTORED, "already_open", true, "diaryLock", 300);
		}

		override public function setUpCar():void
		{
			super.setUpCar();
			var threshold:Threshold = new Threshold("x", "<");
			threshold.threshold = 600;
			threshold.entered.add(checkBooks);
			player.add(threshold);
			player.remove(Sleep);
			carGroup.gotInOrOutOfCar.add(setUpCarBlock);
		}

		private function setUpCarBlock(inCar:Boolean):void
		{
			var carBlock:Entity = getEntityById("carBlock");
			if(!inCar)
				carBlock.remove(Wall);
			else
			{
				if(shellApi.checkEvent(shrink.GOT_CJS_MESSAGE_02))
					carBlock.remove(Wall);
				else
					carBlock.add(new Wall());
			}
		}

		private function checkBooks():void
		{
			if(!shellApi.checkEvent(shrink.IN_CAR))
				return;

			if(shellApi.checkEvent(shrink.KNOCKED_DOWN_BOOK))
			{
				if(shellApi.checkEvent(shrink.IN_SILVAS_OFFICE))
				{
					SceneUtil.lockInput( this );
					addChildGroup( new Ramp( super.overlayContainer ));
				}
				else if(shellApi.checkEvent(shrink.GOT_CJS_MESSAGE_02))
				{
					SceneUtil.lockInput( this );
					addChildGroup( new Jump( super.overlayContainer ));
				}
				else
				{
					Dialog(player.get(Dialog)).sayById("dont_jump_yet");
				}
			}
			else
				Dialog(player.get(Dialog)).sayById("book_block");
		}

		private function onEventTriggered( event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			if(event == blankPaper.LOOK_AWAY_FROM_PAPER)
			{
				takeBackPaper();
			}
			super.onEventTriggered(event, makeCurrent, init, removeEvent);
		}

		override public function useDiaryKey():void
		{
			SceneUtil.lockInput(this);
			TweenUtils.entityTo(getEntityById("cover"),Spatial,1,{scaleX:0, ease:Linear.easeNone,onComplete:openingCover});
		}

		private function openingCover():void
		{
			TweenUtils.entityTo(getEntityById("cover"),Spatial,1,{scaleX:-1, ease:Linear.easeNone,onComplete:coverOpened});
			Display(getEntityById("back").get(Display)).visible = true;
		}

		private function coverOpened():void
		{
			var cover:Entity = getEntityById("cover");
			SceneUtil.lockInput(this, false);
			shellApi.completeEvent(shrink.DIARY_UNLOCKED);
			removeEntity(getEntityById("paperPile"));
		}

		override public function useThumbDrive():void
		{
			if(!shellApi.checkEvent(shrink.LOGGED_ON))
			{
				Dialog(player.get(Dialog)).sayById("not_logged_on");
				return;
			}
			var thumbDrive:Entity = getEntityById("thumbDrive");
			Display(thumbDrive.get(Display)).visible = true;
			Display(getEntityById("uploading").get(Display)).visible = true;
			SceneUtil.lockInput(this);
			TweenUtils.entityTo(getEntityById("loadBar"),Spatial,10,{scaleX:1, ease:Linear.easeNone,onComplete:uploadComplete});
		}

		private function uploadComplete():void
		{
			Display(getEntityById("thumbDrive").get(Display)).visible = false;
			Display(getEntityById("uploading").get(Display)).visible = false
			Dialog(player.get(Dialog)).sayById("copied");
			shellApi.completeEvent(shrink.BACKED_UP_THUMB_DRIVE);
			SceneUtil.lockInput(this, false);
		}

		override public function useBlankPaper():void
		{
			CharUtils.setAnim(player,Place);
			var paper:Entity = getEntityById("blankPaper");
			Display(paper.get(Display)).visible = true;
			Spatial(paper.get( Spatial )).y += 20;
			shellApi.removeItem(shrink.BLANK_PAPER);
			shellApi.completeEvent(shrink.PLACED_PAPER);
			Timeline(player.get(Timeline)).handleLabel("ending", Command.create(inspectPaper, paper));
		}

		private function useTornPage():void
		{
			if(shellApi.checkEvent(shrink.DIARY_UNLOCKED))
			{
				shellApi.completeEvent(shrink.DIARY_RESTORED);
				shellApi.removeItem(shrink.TORN_PAGE);
				Display(getEntityById("diaryPage").get(Display)).visible = true;
				return;
			}
			Dialog(player.get(Dialog)).sayById("scrap_from_diary");
		}

		private function setUpLamp():void
		{
			var jointedLamp:JointedLamp = new JointedLamp();
			// the base of the lamp
			var clip:MovieClip = _hitContainer["lamp"];
			clip.mouseChildren = clip.mouseEnabled = false;
			if( !PlatformUtils.isDesktop )
			{
				BitmapUtils.convertContainer(clip);
			}
			
			var offSet:Point = new Point(clip.x,clip.y);
			clip = clip.lamp1;
			
			var lamp:Entity = setUpLampJoint(jointedLamp,clip,null,0,16);
			Display(lamp.get(Display)).moveToBack();
			var lampSpatial:Spatial = lamp.get(Spatial);
			lampSpatial.x += offSet.x;
			lampSpatial.y += offSet.y;

			// lampArm collider
			var collider:Entity = setUpLampJoint(jointedLamp,clip.lampHit,lampSpatial,90);
			collider.add(new Platform());
			collider.add(new EntityIdList());
			Display(collider.get(Display)).alpha = 0;

			// the arm of the lamp
			clip = clip.lamp2;
			lamp = setUpLampJoint(jointedLamp,clip,lampSpatial,75,16);
			lampSpatial = lamp.get(Spatial);
			Display(lamp.get(Display)).moveToBack();

			// the head of the lamp
			clip = clip.lampHead;
			lamp = setUpLampJoint(jointedLamp,clip,lampSpatial,0,16);
			lampSpatial = lamp.get(Spatial);
			DisplayUtils.moveToOverUnder(clip, Display(getEntityById("lamp2").get(Display)).displayObject);

			// collider for the lamp head
			collider = setUpLampJoint(jointedLamp,clip.platformPos,lampSpatial);
			collider.add(new Platform()).add(jointedLamp).add(new EntityIdList());
			Display(collider.get(Display)).alpha = 0;

			// light switch
			var lightSwitch:Entity = setUpLampJoint(jointedLamp,clip.switchHit,lampSpatial);
			var interaction:Interaction = InteractionCreator.addToEntity(lightSwitch,["click"],clip.switchHit);
			interaction.click.add(Command.create(toggleLightOnOff,clip));
			ToolTipCreator.addToEntity(lightSwitch);
			toggleLightOnOff(lightSwitch,clip);
			toggleLightOnOff(lightSwitch,clip);//called twice so it doesnt change the state
			Display(lightSwitch.get(Display)).alpha = 0;
		}

		private function toggleLightOnOff(lightSwitch:Entity,lampHead:MovieClip):void
		{
			if(shellApi.checkEvent(shrink.LAMP_ON))
				shellApi.removeEvent(shrink.LAMP_ON);
			else
				shellApi.completeEvent(shrink.LAMP_ON);

			lampHead.lampHeadOffVector.visible = !shellApi.checkEvent(shrink.LAMP_ON);
			lampHead.lampHeadOnVector.visible = shellApi.checkEvent(shrink.LAMP_ON);
		}

		private function setUpLampJoint(jointedLamp:JointedLamp,clip:MovieClip,parent:Spatial = null,rotationOffset:Number = 0, rotation:Number = 0):Entity
		{
			clip.mouseChildren = clip.mouseEnabled = false;

			var lamp:Entity = EntityUtils.createSpatialEntity(this, clip,_hitContainer);
			lamp.add(new Id(clip.name));
			var offset:Point = new Point(clip.x,clip.y);

			jointedLamp.setUpJoinOfLight(lamp,parent,offset,rotationOffset,rotation);

			return lamp;
		}

		private function setUpPaper():void
		{
			var clip:MovieClip = _hitContainer["blankPaper"];
			if(shellApi.checkEvent(shrink.CJ_AT_SCHOOL))
			{
				_hitContainer.removeChild(clip);
				return;
			}
			if( !PlatformUtils.isDesktop )
			{
				BitmapUtils.convertContainer(clip);
			}
			var blankPaper:Entity = EntityUtils.createSpatialEntity(this,clip,_hitContainer);
			blankPaper.add(new Id("blankPaper"));
			Display(blankPaper.get(Display)).visible = shellApi.checkEvent(shrink.PAPER_ON_TABLE);
			Display(blankPaper.get(Display)).moveToBack();
			var interaction:Interaction = InteractionCreator.addToEntity(blankPaper,["click"],clip);
			interaction.click.add(inspectPaper);
			if(shellApi.checkEvent(shrink.PAPER_ON_TABLE))
			{
				ToolTipCreator.addToEntity(blankPaper);
				Spatial( blankPaper.get( Spatial )).y += 20;
			}
		}

		private function inspectPaper(entity:Entity):void
		{
			var lamp:Entity = getEntityById("platformPos");
			var lampDown:Boolean = JointedLamp(lamp.get(JointedLamp)).lampIsDown;
			if(lampDown)
				shellApi.completeEvent(shrink.LAMP_DOWN);
			else
				shellApi.removeEvent(shrink.LAMP_DOWN);
			blankPaper = addChildGroup( new BlankPaperPopup( super.overlayContainer )) as BlankPaperPopup;
		}

		private function takeBackPaper():void
		{
			if(shellApi.checkEvent(shrink.CJ_AT_SCHOOL))
			{
				removeEntity(getEntityById("blankPaper"));
				ItemGroup(getGroupById(ItemGroup.GROUP_ID)).showAndGetItem(shrink.BLANK_PAPER);
			}
		}

		private function setUpDiary():void
		{
			var clip:MovieClip = _hitContainer["diaryCover"];
			if( !PlatformUtils.isDesktop )
			{
				BitmapUtils.convertContainer(clip);
			}
			var cover:Entity = EntityUtils.createSpatialEntity(this,clip,_hitContainer);
			cover.add(new Id("cover"));
			Display(cover.get(Display)).moveToBack();
			var back:Entity = EntityUtils.createSpatialEntity(this,clip.back,clip);
			back.add(new Id("back"));

			if(shellApi.checkEvent(shrink.DIARY_UNLOCKED))
			{
				Spatial(cover.get(Spatial)).scaleX = -1;
				removeEntity(getEntityById("paperPile"));
			}
			else
				Display(back.get(Display)).visible = false;

			clip = hitContainer["diaryPage"];
			if( !PlatformUtils.isDesktop )
			{
				BitmapUtils.convertContainer(clip);
			}
			var page:Entity = EntityUtils.createSpatialEntity(this,clip,_hitContainer);
			page.add(new Id("diaryPage"));
			Display(page.get(Display)).visible = shellApi.checkEvent(shrink.DIARY_RESTORED);
			Display(page.get(Display)).moveToBack();

			clip = _hitContainer["diaryLock"];
			if( !PlatformUtils.isDesktop )
			{
				BitmapUtils.convertContainer(clip);
			}
			var lock:Entity = EntityUtils.createSpatialEntity(this,clip,_hitContainer);
			lock.add(new Id("diaryLock"));
			var interaction:Interaction = InteractionCreator.addToEntity(lock,["click"],clip);
			interaction.click.add(checkDiary);
			ToolTipCreator.addToEntity(lock);
			Display(lock.get(Display)).alpha = 0;
		}

		private function checkDiary(...args):void
		{
			if(shellApi.checkEvent(shrink.DIARY_UNLOCKED))
			{
				if(shellApi.checkEvent(shrink.DIARY_RESTORED))
					diary = addChildGroup( new DiaryPagePopup( super.overlayContainer )) as DiaryPagePopup;
				else
					Dialog(player.get(Dialog)).sayById("page_torn");
			}
			else
				Dialog(player.get(Dialog)).sayById("diary_locked");
		}

		private function setUpComputer():void
		{
			var parts:Array = ["thumbDrive","uploading","loginBox"];
			for(var i:int = 0; i<parts.length; i++)
			{
				var part:String = parts[i];
				var clip:MovieClip = _hitContainer[part];
				if( !PlatformUtils.isDesktop )
				{
					BitmapUtils.convertContainer(clip);
				}
				var entity:Entity = EntityUtils.createSpatialEntity(this, clip,_hitContainer);
				entity.add(new Id(part));
				Display(entity.get(Display)).visible = false;
				Display(entity.get(Display)).moveToBack();
			}

			setUpLoadingBar();

			setUpLogInBox();

			setUpLapTopHit();

			setUpKeys();
		}

		private function setUpLoadingBar():void
		{
			var entity:Entity = getEntityById("uploading");
			var clip:MovieClip = Display(entity.get(Display)).displayObject  as MovieClip;
			var loadBar:Entity = EntityUtils.createSpatialEntity(this,clip.loadBar,clip);
			loadBar.add(new Id("loadBar"));
			Spatial(loadBar.get(Spatial)).scaleX = 0;
		}

		private function setUpLogInBox():void
		{
			var entity:Entity = getEntityById("loginBox");
			var clip:MovieClip = Display(entity.get(Display)).displayObject as MovieClip;

			TimelineUtils.convertClip(clip,this,entity,null,false);
			Timeline(entity.get(Timeline)).handleLabel("ending",tryAgain,false);
			Display(entity.get(Display)).visible = !shellApi.checkEvent(shrink.LOGGED_ON);
			loginText = TextUtils.refreshText(clip.fldLogin, "Orange Kid");
			sampleText 	=	clip.sample;
			trace();
		}

		private function setUpLapTopHit():void
		{
			var clip:MovieClip = _hitContainer["laptopHit"];
			var hit:Entity = EntityUtils.createSpatialEntity(this,clip,_hitContainer);
			hit.add(new SceneInteraction()).add(new Id("laptopHit"));
			InteractionCreator.addToEntity(hit,["click"],clip);
			var interaction:Interaction = hit.get( Interaction );
			interaction.click.add( toggleApproachComputer );

			var sceneInteraction:SceneInteraction = hit.get( SceneInteraction );
	//		sceneInteraction.lockInput = true;
			sceneInteraction.reached.add(clickComputer);


			ToolTipCreator.addToEntity(hit);
			Display(hit.get(Display)).alpha = 0;
			Display(hit.get(Display)).moveToBack();
		}

		private function setUpKeys():void
		{
			var audioGroup:AudioGroup = getGroupById( AudioGroup.GROUP_ID ) as AudioGroup;
			var creator:HitCreator = new HitCreator();

			for(var i:int = 1; i <= 8; i++)
			{
				var clip:MovieClip = _hitContainer["key"+i];
				var key:Entity = EntityUtils.createSpatialEntity(this,clip,_hitContainer);
				key.add(new Platform()).add(new Id("key"+i));
				var keyPress:Entity = EntityUtils.createMovingEntity(this,clip.keyClip,clip);
				Display(keyPress.get(Display)).displayObject.mask = clip.keyMask;
				keyPress.add(new Press(new Point(10,20),key));
				Display(key.get(Display)).moveToBack();

				creator.addHitSoundsToEntity( key, audioGroup.audioData, shellApi );
				trace();
			}
		}

		private function toggleApproachComputer( laptopHit:Entity ):void
		{
			var charMotion:CharacterMotionControl = player.get( CharacterMotionControl );
			charMotion.jumpVelocity = -500;
			charMotion.jumpTargetVelocity = 500;
		}

		private function clickComputer(player:Entity, entity:Entity):void
		{
			if( !_attemptLogin )
			{
				_attemptLogin = true;
				if(shellApi.checkEvent(shrink.LOGGED_ON))
				{
					logOn();
				}
				else
				{
					logIn();
				}
			}
		}

		private function logIn():void
		{
			loginText.text ="";
			sampleText.visible 	=	false

			player.remove( TargetEntity );

			keyboard = addChildGroup(new KeyboardPopup()) as KeyboardPopup;
			keyboard.config(null,null,true,true,true,false);
			keyboard.groupPrefix = groupPrefix + "keyboard/";
			keyboard.keyboardType = KeyboardCreator.KEYBOARD_ALL;
			keyboard.textFormat = new TextFormat("CreativeBlock BB", 24, 0xFFFFFF);
			keyboard.bufferRatio = .1;
			keyboard.init( overlayContainer );

			keyboard.keyInput.add( onKeyInput );
			keyboard.ready.addOnce( onKeyboardLoaded );
			keyboard.removed.addOnce(confirmLogin);

			var logOnScreen:Entity = getEntityById("loginBox");
			Display(logOnScreen.get(Display)).visible = true;
			SceneUtil.setCameraPoint(this,logOnScreen.get(Spatial).x, logOnScreen.get(Spatial).y + 250);
		}

		private function onKeyboardLoaded( keyboard:KeyboardPopup ):void
		{
			keyboard.setTransitions();
		}

		private function onKeyInput(value:String):void
		{
			moveToKey(value.charCodeAt()%8 + 1);
			if(value == KeyboardCreator.COMMAND_DELETE)
			{
				loginText.text = loginText.text.substr(0,loginText.text.length - 1).toLowerCase();
				return;
			}
			if(value == KeyboardCreator.COMMAND_ENTER)
			{
				keyboard.close(true);
				return;
			}
			loginText.text += value.toLowerCase();
		}

		private function moveToKey(keyNumber:int = -1):void
		{
			if(keyNumber == -1)
				keyNumber = int(Math.random() * 8) + 1;

			var key:Entity = getEntityById("key"+ keyNumber);
			var point:Point = new Point(key.get(Spatial).x, key.get(Spatial).y);
			CharUtils.moveToTarget(player,point.x,point.y - 150,false,null,new Point(100, 100)).ignorePlatformTarget = true;
		}

		private function tryAgain():void
		{
			var entity:Entity 	=	getEntityById( "loginBox" );
			Timeline( entity.get( Timeline )).gotoAndStop( 0 );
			SceneUtil.lockInput( this,false );

			sampleText.visible 	=	true;
			var clip:MovieClip = Display( entity.get( Display )).displayObject as MovieClip;

			shellApi.defaultCursor = ToolTipType.NAVIGATION_ARROW;
		}

		private function confirmLogin(...args):void
		{
			SceneUtil.setCameraTarget(this, player);

			if( !player.has( TargetEntity ))
			{
				player.add( _targetEntity );
			}
			if(loginText.text == PASSWORD)
			{
				logOn();
				shellApi.completeEvent(shrink.LOGGED_ON);
			}
			else
			{
				if(loginText.text == MARIE_CURIE)
					Dialog(player.get(Dialog)).sayById("password_check");
				loginText.text= "";
				Timeline(getEntityById("loginBox").get(Timeline)).play();
				SceneUtil.lockInput(this);

				var charMotion:CharacterMotionControl = player.get( CharacterMotionControl );
				charMotion.jumpVelocity = -900;
				charMotion.jumpTargetVelocity = 950;

				_attemptLogin = false;
			}
		}

		private function logOn():void
		{
			Display(getEntityById("loginBox").get(Display)).visible = false;

			var email:OneShotPopup = new OneShotPopup(overlayContainer, "email.swf", "scenes/shrink/bedroomShrunk01/");
			email.removed.addOnce(checkIfHasThumbDrive);

			addChildGroup(email);
		}

		private function checkIfHasThumbDrive(...args):void
		{
			shellApi.defaultCursor = ToolTipType.NAVIGATION_ARROW;

			var charMotion:CharacterMotionControl = player.get( CharacterMotionControl );
			charMotion.jumpVelocity = -900;
			charMotion.jumpTargetVelocity = 950;
			_attemptLogin = false;

			if( !player.has( TargetEntity ))
			{
				player.add( _targetEntity );
			}

			SceneUtil.lockInput( this, false );

			if(shellApi.checkHasItem(shrink.THUMB_DRIVE) && !shellApi.checkEvent(shrink.BACKED_UP_THUMB_DRIVE))
				shellApi.triggerEvent(shrink.THUMB_DRIVE);
		}

		private function setUpMessage():void
		{
			var clip:MovieClip = _hitContainer["microscopeMessage"];
			var message:Entity = EntityUtils.createSpatialEntity(this,clip,_hitContainer);
			InteractionCreator.addToEntity(message,["click"],clip);
			Interaction(message.get(Interaction)).click.add(clickMessage);
			ToolTipCreator.addToEntity(message);
			Display(message.get(Display)).alpha = 0;
		}

		private function clickMessage(entity:Entity):void
		{
			addChildGroup( new MicroscopeMessage( super.overlayContainer )) as MicroscopeMessage;
		}

		private function setUpNecklace():void
		{
			var clip:MovieClip = _hitContainer["necklace"];
			if( !PlatformUtils.isDesktop )
			{
				BitmapUtils.convertContainer(clip);
			}
			var necklace:Entity = EntityUtils.createMovingEntity(this,clip,_hitContainer);
			necklace.add(new Swing());
		}

		private function setUpEyes():void
		{
			for(var i:int = 0; i < 3; i++)
			{
				var clip:MovieClip = _hitContainer["eyes"+i];
				if( !PlatformUtils.isDesktop )
				{
					BitmapUtils.convertContainer(clip);
				}
				var eyes:Entity = TimelineUtils.convertClip(clip,this,null);
				var time:Timeline = eyes.get(Timeline);
				time.handleLabel("open", Command.create(openEyes, time),false);
				time.handleLabel("close", Command.create(blinkEyes, time),false);
				time.gotoAndPlay("close");
			}
		}

		private function blinkEyes(timeline:Timeline):void
		{
			SceneUtil.addTimedEvent(this, new TimedEvent(2 + Math.random() * 3,1,Command.create(blink, timeline)));
		}

		private function openEyes(timeline:Timeline):void
		{
			timeline.stop();
		}

		private function blink(timeline:Timeline):void
		{
			timeline.play();
		}

		private function setUpDial():void
		{
			var clip:MovieClip = _hitContainer["dial"];
			var dial:Entity = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
			Display(dial.get(Display)).moveToBack();
			clip = _hitContainer["dialHit"];
			var collider:Entity = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
			collider.add(new Platform());
			Display(collider.get(Display)).alpha = 0;
			dial.add(new WalkToTurnDial(collider,true,true,180, 0,-.5));
			clip = _hitContainer["dialLight"];
			var light:Entity = TimelineUtils.convertClip(clip,this,null,null,false);
			var time:Timeline = light.get(Timeline);
			var thermostat:WalkToTurnDial = dial.get(WalkToTurnDial);
			thermostat.dialOff.add(Command.create(turnOffHeat,time));
			thermostat.dialOn.add(Command.create(turnOnHeat,time));
			if(shellApi.checkEvent(shrink.VENT_ON))
			{
				Spatial(dial.get(Spatial)).rotation = 90;
				turnOnHeat(time);
				WalkToTurnDial(dial.get(WalkToTurnDial)).value += 45;
			}
			else
			{
				Spatial(dial.get(Spatial)).rotation = -90;
				WalkToTurnDial(dial.get(WalkToTurnDial)).value -= 45;
			}
		}

		private function turnOnHeat(timeline:Timeline):void
		{
			shellApi.completeEvent(shrink.VENT_ON);
			timeline.gotoAndStop("on");
		}

		private function turnOffHeat(timeline:Timeline):void
		{
			shellApi.removeEvent(shrink.VENT_ON);
			timeline.gotoAndStop("off");
		}

		private function setUpBooks():void
		{
			var clip:MovieClip = _hitContainer["bookRamp"];
			var bookRamp:Entity = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
			bookRamp.add(new Id("bookRamp"));

			clip = _hitContainer["book"];

			if(shellApi.checkEvent(shrink.KNOCKED_DOWN_BOOK))
			{
				_hitContainer.removeChild(clip);
				_hitContainer.removeChild(_hitContainer["bookHit"]);
				removeEntity(getEntityById("tessTreeBook"));
			}
			else
			{
				var book:Entity = EntityUtils.createMovingEntity(this, clip, _hitContainer);
				book.add(new Id(clip.name));
				clip = _hitContainer["bookHit"];
				var creator:SceneObjectCreator = new SceneObjectCreator();
				var hit:Entity = creator.createBox(clip, 0,_hitContainer, NaN, NaN, null, null, sceneData.bounds, this, null, null, 200);
				hit.add(new HitTest()).add(new EntityIdList()).add(new Id(clip.name)).add(new PlatformCollider());
				Display(hit.get(Display)).alpha = 0;
				var follow:FollowTarget = new FollowTarget(hit.get(Spatial));
				follow.offset = new Point(0, clip.height / 2);

				var threshold:Threshold = new Threshold("x", "<");
				threshold.threshold = 450;
				threshold.entered.addOnce(tip);
				book.add(follow).add(threshold);

				Display(bookRamp.get(Display)).visible = false;
				getEntityById("ramp").remove(Platform);
			}
		}

		private function tip():void
		{
			var hit:Entity = getEntityById("bookHit");
			var book:Entity = getEntityById("book");
			book.remove(FollowTarget);
			var follow:FollowTarget = new FollowTarget(book.get(Spatial));
			follow.offset = new Point(0, - Spatial(hit.get(Spatial)).height / 2);
			hit.add(follow);

			var tipComponent:Tip = new Tip(hit.get(HitTest),this,-30);
			tipComponent.tipped.add(tipBook);
			book.add(tipComponent);

			Tip.addNeededSystems(this);
		}

		private function tipBook(book:Entity):void
		{
			book.remove(Tip);
			removeEntity(getEntityById("bookHit"));
			TweenUtils.entityTo(book,Spatial,1,{y:1500, ease:Quad.easeIn,onComplete:Command.create(bookFell, book)});
		}

		private function bookFell(book:Entity):void
		{
			removeEntity(book);
			removeEntity(getEntityById("book"));
			Display(getEntityById("bookRamp").get(Display)).visible = true;
			getEntityById("ramp").add(new Platform());
			shellApi.completeEvent(shrink.KNOCKED_DOWN_BOOK);
		}
	}
}
