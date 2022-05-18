package game.scenes.virusHunter.mainStreet
{
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.systems.CameraSystem;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.character.animation.AnimationControl;
	import game.components.hit.Climb;
	import game.components.hit.Zone;
	import game.components.motion.MotionControl;
	import game.components.motion.Navigation;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.components.timeline.TimelineClip;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Drink;
	import game.data.animation.entity.character.Place;
	import game.data.animation.entity.character.Sleep;
	import game.data.animation.entity.character.Stand;
	import game.data.animation.entity.character.Stomp;
	import game.data.animation.entity.character.Think;
	import game.data.animation.entity.character.Throw;
	import game.data.scene.characterDialog.DialogData;
	import game.data.sound.SoundModifier;
	import game.data.ui.ToolTipType;
	import game.particles.emitter.BlowingLeaves;
	import game.scene.template.PlatformerGameScene;
	import game.scene.template.ads.AdBlimpGroup;
	import game.scenes.custom.AdMiniBillboard;
	import game.scenes.virusHunter.VirusHunterEvents;
	import game.scenes.virusHunter.backRoom.BlueprintPopup;
	import game.scenes.virusHunter.bloodStream.BloodStream;
	import game.scenes.virusHunter.day2Mouth.Day2Mouth;
	import game.systems.actionChain.ActionChain;
	import game.systems.actionChain.ActionCommand;
	import game.systems.actionChain.actions.AnimationAction;
	import game.systems.actionChain.actions.CallFunctionAction;
	import game.systems.actionChain.actions.MoveAction;
	import game.systems.actionChain.actions.TalkAction;
	import game.systems.actionChain.actions.WaitAction;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	import game.util.Utils;
	
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class MainStreet extends PlatformerGameScene
	{
		private var _leavesEntity:Entity;
		private var _youngPerson:Entity;
		private var _citizen2:Entity;
		private var _notesEntity:Entity;
		private var _radioDialog:MovieClip;
		private var _notesEmitter:NotesParticleEffect;
		private var _radio:MovieClip;
		private var actionChain:ActionChain;
		private var action:ActionCommand;
		//private var _nestZoneEntity:Entity;
		private var _hookHintZoneEntity:Entity;
		private var _bertShell:Entity;
		private var _ropeEntity:Entity;
		private var _ropeHit:Entity;
		private var _animationsLayer:Entity;
		private var _animationsContainer:DisplayObjectContainer;
		private var _bertZoneEntity:Entity;
		//private var _inNestZone:Boolean = false;
		private var _inBertZone:Boolean = false;
		private var virusEvents:VirusHunterEvents;
		private var _shreddedDocumentsPopup:BlueprintPopup
		
		private var _vanEntity:Entity;
		private var _vanWheel1Entity:Entity;
		private var _vanWheel2Entity:Entity;
		private var _manWithShades:Entity;
		private var camera:CameraSystem;
		private var savedCameraRate:Number;
		private var radioSoundEntity:Entity;
		private var radioAudio:Audio;
		
		private var girl:Entity;
		private var dog:Entity;
		
		public function MainStreet()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/virusHunter/mainStreet/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			virusEvents = super.events as VirusHunterEvents;
			super.shellApi.eventTriggered.add(handleEventTriggered);
			
			// tool tip on rope
			var rope:Entity = EntityUtils.createSpatialEntity(super, super.hitContainer["climb1"]);
			rope.get(Display).alpha = 0;
			// tool tip text (blank if blimp takeover)
			var toolTipText:String = (super.getGroupById(AdBlimpGroup.GROUP_ID) == null) ? "TRAVEL" : "";			
			ToolTipCreator.addToEntity(rope,ToolTipType.EXIT_UP, toolTipText);
			// rope behavior
			var interaction:Interaction = InteractionCreator.addToEntity(rope, [InteractionCreator.CLICK]);
			interaction.click.add(climbToBlimp);

			_youngPerson = super.getEntityById("youngPerson");
			_bertShell = super.getEntityById("bertShell");
			_manWithShades = super.getEntityById("manWithShades");
			_citizen2 = super.getEntityById("citizen2");
			
			_animationsLayer = super.getEntityById("interactive2");
			_animationsContainer = Display(_animationsLayer.get(Display)).displayObject;
			
			_radioDialog = MovieClip(super._hitContainer).radioDialog;
			super.convertToBitmap(_radioDialog.art)
			_radioDialog.visible = false;
			_radioDialog.scaleX = _radioDialog.scaleY = 0;
			_radioDialog.t = 0;
			_radioDialog.startY = _radioDialog.y;
			
			_radio = MovieClip(super._hitContainer).radio;
			super.convertToBitmap(_radio.art);
			_radio.t = 0;
			_radio.startY = _radio.y;
			super._hitContainer.addEventListener("enterFrame", moveRadio);
			
			//leaves particle effect
			var emitter:BlowingLeaves = new BlowingLeaves(); 
			_leavesEntity = EmitterCreator.create(this, super._hitContainer, emitter, 0, 0); 
			emitter.init( new LineZone( new Point(0,super.sceneData.cameraLimits.bottom/2), new Point(0,super.sceneData.cameraLimits.bottom) ), new Point(300,50), new RectangleZone(super.sceneData.cameraLimits.left, super.sceneData.cameraLimits.top, super.sceneData.cameraLimits.right, super.sceneData.cameraLimits.bottom) );
			
			//music notes particle effect (from radio)
			_notesEmitter = new NotesParticleEffect(); 
			_notesEntity = EmitterCreator.create(this, super._hitContainer, _notesEmitter, _radio.x + 30, _radio.y - 30); 
			_notesEmitter.init();
			
			//approaching youngPerson should initiate their radio sequence instead of starting regular dialog
			var sceneInteraction:SceneInteraction = _youngPerson.get(SceneInteraction);
			// removeAll removes the default behavior
			sceneInteraction.reached.removeAll();
			// add a custom handler
			sceneInteraction.reached.add(reachedYoungPerson);
			
			var ropeClip:MovieClip = MovieClip(_animationsContainer).rope;
			
			//check to see if they should be put back in the body
			if (super.shellApi.checkEvent( virusEvents.ENTERED_JOE ))
			{
				if(!super.shellApi.checkHasItem(virusEvents.MEDAL_VIRUS))
				{
					//they are supposed to be in the body. load the bloodStream
					super.shellApi.loadScene(BloodStream,0,0,null,0,0);
				}
				else
				{
					if(this.shellApi.checkEvent(virusEvents.ENTERED_DOG) &&
						!this.shellApi.checkEvent(virusEvents.WORM_BOSS_DEFEATED))
					{
						//They've entered the Dog but haven't beaten the Worm Boss yet. Put them back in the Mouth.
						this.shellApi.loadScene(Day2Mouth);
					}
				}
				
			}
			
			if ( super.shellApi.checkEvent(virusEvents.USED_RESISTANCE_BAND) ) {
				ropeClip.gotoAndStop(ropeClip.totalFrames);
			}
			else {
				_ropeEntity = TimelineUtils.convertClip( ropeClip, this );
				TimelineClip(_ropeEntity.get(TimelineClip)).mc.visible = false;
				_ropeHit = super.getEntityById("climb2");
				_ropeHit.remove(Climb);
				
				var ropeTimeline:Timeline = _ropeEntity.get(Timeline);
				ropeTimeline.handleLabel("land", playSnagHookSound);
				
				/*_nestZoneEntity = super.getEntityById( "nestZone" );
				var nestZone:Zone = _nestZoneEntity.get( Zone );
				nestZone.pointHit = true;
				nestZone.entered.add(enterNestZone);
				nestZone.exitted.add(exitNestZone);*/
				
				_hookHintZoneEntity = super.getEntityById( "hookHintZone" );
				var hookHintZone:Zone = _hookHintZoneEntity.get( Zone );
				hookHintZone.pointHit = true;
				hookHintZone.entered.addOnce(doHookHint);
			}
			
			if ( super.shellApi.checkEvent(virusEvents.SAW_VAN_ON_MAIN) ) {
				removeVan();
			}
			else {
				setVan();
			}
			
			_bertZoneEntity = super.getEntityById( "bertZone" );
			var bertZone:Zone = _bertZoneEntity.get( Zone );
			if ( !super.shellApi.checkEvent(virusEvents.TALKED_TO_BERT) ) {
				bertZone.entered.addOnce(showBertTalkingOnRadio);
			}
			bertZone.entered.add(enterBertZone);
			bertZone.exitted.add(exitBertZone);
			
			//birds are purely visual
			//Guess there's only one bird that chirps.
			for(var i:int = 1; i <= 1; i++)
			{
				var bird:Entity = EntityUtils.createSpatialEntity(this, _animationsContainer["bird" + i]);
				TimelineUtils.convertClip(_animationsContainer["bird" + i], this, bird);
				
				var timeline:Timeline = bird.get(Timeline);
				timeline.handleLabel("chirp", Command.create(birdChirp, bird), false);
				
				bird.add(new Id("bird" + i));
				bird.add(new Audio());
				bird.add(new AudioRange(900));
			}
			TimelineUtils.convertClip( MovieClip(_animationsContainer).bird2, this );
			
			//positional radio sound
			radioSoundEntity = new Entity();
			radioAudio = new Audio();
			radioAudio.play(SoundManager.MUSIC_PATH + "Techno_Jam_Filtered.mp3", true, [SoundModifier.POSITION, SoundModifier.EFFECTS]);
			//entity.add(new Display(super._hitContainer["soundSource"]));
			radioSoundEntity.add(radioAudio);
			radioSoundEntity.add(new Spatial(1350, 1440));
			radioSoundEntity.add(new AudioRange(600, 0, 1, Quad.easeIn));
			radioSoundEntity.add(new Id("soundSource"));
			super.addEntity(radioSoundEntity);
			
			this.setupBertRadio();
			
			var minibillboard:AdMiniBillboard = new AdMiniBillboard(this,super.shellApi, new Point(685, 1080),"minibillboard/minibillboardMedLegs.swf");	

			this.setupDay2();
		}
		
		private function climbToBlimp(ent:Entity):void
		{
			var rope:MovieClip = super.hitContainer["climb1"];
			var top:Number = rope.y - rope.height / 2;
			CharUtils.followPath(player, new <Point>[new Point(rope.x, top)], playerReachedTopBlimp, false, false, new Point(40, 40));
		}		
		
		private function playerReachedTopBlimp(...args):void
		{
			// if blimp takeover not active, then load map
			if (super.getGroupById(AdBlimpGroup.GROUP_ID) == null)
				getEntityById("exitToMap").get(SceneInteraction).activated = true;
		}
		
		private function setupBertRadio():void
		{
			var radio:Entity = new Entity();
			this.addEntity(radio);
			
			var audio:Audio = new Audio();
			radio.add(audio);
			audio.play(SoundManager.EFFECTS_PATH + "pirate_radio_chatter_01.mp3", true, [SoundModifier.EFFECTS, SoundModifier.POSITION]);
			
			radio.add(new Spatial(485, 360));
			radio.add(new AudioRange(600, 0, 0.5, Quad.easeIn));
		}
		
		private function birdChirp(bird:Entity):void
		{
			var audio:Audio = bird.get(Audio);
			audio.play(SoundManager.EFFECTS_PATH + "bird_chirp_single_01.mp3", false, [SoundModifier.EFFECTS, SoundModifier.POSITION]);
		}
		
		private function dogBark(player:Entity, dog:Entity):void
		{
			var audio:Audio = dog.get(Audio);
			audio.play(SoundManager.EFFECTS_PATH + "dog_bark_01.mp3", false, [SoundModifier.EFFECTS, SoundModifier.POSITION]);
		}
		
		private function setupDay2():void
		{
			//Used before this was pushed live to prevent people from playing Day 2
			//if(!this.shellApi.siteProxy.isTestServer()) return;
			
			if(!this.shellApi.checkHasItem(this.virusEvents.MEDAL_VIRUS)) return;
			
			this.girl = this.getEntityById("girl");
			this.dog = this.getEntityById("dog");
			
			if(this.shellApi.checkEvent(this.virusEvents.DOG_IN_MAIN_STREET))
			{
				var sleep:game.components.entity.Sleep = this.dog.get(game.components.entity.Sleep);
				sleep.sleeping = false;
				sleep.ignoreOffscreenSleep = true;
				
				this.dog.add(new Audio());
				this.dog.add(new AudioRange(900));
				
				ToolTipCreator.addToEntity(this.dog);
				
				var interaction:SceneInteraction = this.dog.get(SceneInteraction);
				interaction.triggered.add(dogBark);
				
				if(!this.shellApi.checkEvent(this.virusEvents.GIRL_IN_MAIN_STREET))
				{
					this.dog.get(Spatial).x = 1700;
					
					CharUtils.setAnim(this.dog, game.data.animation.entity.character.Sleep);
					Display(this.dog.get(Display)).moveToFront();
					interaction.reached.add(handleDogRun);
				}
				else
				{
					var spatial:Spatial;
					
					var lange:Entity = this.getEntityById("dr_lange");
					
					spatial = this.dog.get(Spatial);
					spatial.x = 2410;
					
					ToolTipCreator.addToEntity(this.dog);
					
					if(!this.shellApi.checkEvent(virusEvents.EXITED_DOG))
					{
						SceneUtil.lockInput(this);
						
						CharUtils.setDirection(this.player, false);
						spatial = this.player.get(Spatial);
						spatial.x = 2500;
						spatial.y = 1440;
						
						sleep = this.girl.get(game.components.entity.Sleep);
						sleep.sleeping = false;
						sleep.ignoreOffscreenSleep = true;
						
						sleep = lange.get(game.components.entity.Sleep);
						sleep.sleeping = false;
						sleep.ignoreOffscreenSleep = true;
						
						Dialog(girl.get(Dialog)).sayById("thank_you");
					}
				}
			}
		}
		
		private function handleDogRun(player:Entity, dog:Entity):void
		{
			Dialog(player.get(Dialog)).sayById("frenzied");
			CharUtils.stateDrivenOn(dog);
			
			var x:Number = Utils.randNumInRange(this.sceneData.cameraLimits.left + 100, this.sceneData.cameraLimits.right - 100);
			CharUtils.followPath(dog, new <Point>[new Point(x, dog.get(Spatial).y)], handleDogRunPath);
		}
		
		private function handleDogRunPath(dog:Entity):void
		{
			CharUtils.setAnim(dog, game.data.animation.entity.character.Sleep);
		}
		
		private function handleFalafelPlace():void
		{
			if(!this.dog) return;
			
			CharUtils.stateDrivenOn(dog);
			var spatial:Spatial = this.dog.get(Spatial);
			
			var clip:MovieClip = this._hitContainer["falafel"];
			clip.x = this.player.get(Spatial).x;
			clip.y = 1440;
			this._hitContainer.setChildIndex(clip, this._hitContainer.numChildren - 1);
			
			var x:Number = clip.x;
			if(x > spatial.x) x -= 35;
			else x += 35;
			
			CharUtils.followPath(this.dog, new <Point>[new Point(x, clip.y)], handleDogEating, true, false);
		}
		
		private function handleDogEating(dog:Entity):void
		{
			CharUtils.setAnim(dog, Drink);
			
			var dialog:Dialog = this.player.get(Dialog);
			dialog.sayById("stay");
			dialog.complete.addOnce(loadMouth);
		}
		
		private function loadMouth(data:DialogData):void
		{
			this.shellApi.completeEvent(virusEvents.ENTERED_DOG);
			this.shellApi.loadScene(Day2Mouth, 290, 1160);
		}
		
		private function handleEventTriggered(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{trace(event);
			if(event == "useResistanceBand")
			{
				//if (_inNestZone && !super.shellApi.checkEvent(virusEvents.USED_RESISTANCE_BAND)) {
				if (!super.shellApi.checkEvent(virusEvents.USED_RESISTANCE_BAND)
					&& Math.abs(Spatial(super.player.get(Spatial)).x - Spatial(_hookHintZoneEntity.get(Spatial)).x) < 70
					&& Math.abs(Spatial(super.player.get(Spatial)).y - (Spatial(_hookHintZoneEntity.get(Spatial)).y - 40)) < 50) {
					
					useResistanceBand();
				}
				else {
					Dialog(super.player.get(Dialog)).sayById("cantUseResistanceBand");
				}
			}
			else if(event == "useShreddedDocuments")
			{
				if (_inBertZone) {
					useShreddedDocuments();
				}
				else {
					Dialog(super.player.get(Dialog)).sayById("cantUseShreddedDocuments");
				}
			}
			else if(event == "openShreddedDocumentsPopup")
			{
				openShreddedDocumentsPopup();
			}
			else if(event == "talkToBert")
			{
				super.shellApi.completeEvent(virusEvents.TALKED_TO_BERT);
			}
			else if(event == "finishRadioTalk")
			{
				finishRadioTalk();
			}
			else if(event == "gotItem_pdcIdBadge")
			{				
				SceneUtil.lockInput(this, false);
			}
			else if(event == "takeCloserLook")
			{				
				//make blueprint popup visible again and add close trigger
				reopenShreds();
			}
			else if(event == "useFalafel")
			{
				CharUtils.setAnim(this.player, Place);
				
				var timeline:Timeline = this.player.get(Timeline);
				timeline.handleLabel("trigger", handleFalafelPlace);
			}
			else if(event == "exited_dog")
			{
				this.shellApi.getItem("flyingAce", null, true);
				SceneUtil.lockInput(this, false);
			}
		}
		
		private function playSnagHookSound():void
		{
			super.shellApi.triggerEvent("playSnagSound");
		}
		
		private function removeVan():void
		{
			super.removeEntity(_manWithShades);
			MovieClip(super._hitContainer).van.visible = false;
		}
		
		private function setVan():void
		{
			MotionUtils.zeroMotion(super.player, "x");
			CharUtils.lockControls(super.player, true, true);
			SceneUtil.lockInput(this, true);
			SceneUtil.addTimedEvent( this, new TimedEvent( 2, 1, panToVan ) );
			
			game.components.entity.Sleep(_manWithShades.get(game.components.entity.Sleep)).ignoreOffscreenSleep = true;
			game.components.entity.Sleep(_manWithShades.get(game.components.entity.Sleep)).sleeping = false;
			CharUtils.stateDrivenOff(_manWithShades, 99999);
			SceneInteraction(_manWithShades.get(SceneInteraction)).offsetY = 100;
			CharUtils.setDirection(_manWithShades, true);
			
			var vanClip:MovieClip = MovieClip(super._hitContainer).van;
			_vanEntity = EntityUtils.createMovingEntity(this, vanClip, super._hitContainer);
			
			var vanWheel1Clip:MovieClip = vanClip.wheel1;
			_vanWheel1Entity = EntityUtils.createMovingEntity(this, vanWheel1Clip, vanClip);
			var vanWheel2Clip:MovieClip = vanClip.wheel2;
			_vanWheel2Entity = EntityUtils.createMovingEntity(this, vanWheel2Clip, vanClip);
			
			super._hitContainer.setChildIndex(_vanEntity.get(Display).displayObject, 0);
			super._hitContainer.setChildIndex(_manWithShades.get(Display).displayObject, 0);
			
			super._hitContainer.setChildIndex(_radio, 0);
		}
		
		private function panToVan():void
		{
			camera = this.getSystem( CameraSystem ) as CameraSystem;
			camera.jumpToTarget = false;
			savedCameraRate = camera.rate;
			camera.rate = 0.05;
			camera.target = _manWithShades.get(Spatial);
			vanLeaves();
		}
		
		private function vanLeaves():void
		{			
			_manWithShades.remove(AnimationControl);
			_manWithShades.remove(MotionControl);
			_manWithShades.remove(Navigation);
			
			_manWithShades.add( new Motion() );
			Motion(_manWithShades.get(Motion)).velocity = new Point(600, 0);
			//Motion(_manWithShades.get(Motion)).acceleration = new Point(500, 0);
			
			Motion(_vanEntity.get(Motion)).velocity = new Point(600, 0);
			//Motion(_vanEntity.get(Motion)).acceleration = new Point(500, 0);
			
			Motion(_vanWheel1Entity.get(Motion)).rotationVelocity = -600;
			//Motion(_vanWheel1Entity.get(Motion)).rotationAcceleration = 500;
			
			Motion(_vanWheel2Entity.get(Motion)).rotationVelocity = -600;
			//Motion(_vanWheel2Entity.get(Motion)).rotationAcceleration = 500;
			
			SceneUtil.addTimedEvent( this, new TimedEvent( 2.1, 1, finishVanLeaves ) );
			
			super.shellApi.triggerEvent("playVanSound");
		}
		
		private function finishVanLeaves():void
		{
			super.shellApi.completeEvent(virusEvents.SAW_VAN_ON_MAIN);
			camera.rate = savedCameraRate;
			camera.target = super.player.get(Spatial);
			SceneUtil.lockInput(this, false);
			CharUtils.lockControls(super.player, false, false);
			
			Dialog(_citizen2.get(Dialog)).sayById("walkingHere");
			CharUtils.setAnim(_citizen2, Stomp);
			CharUtils.setDirection(_citizen2, false); //for some reason this isn't flipping the npc
			//CharacterMotionControl(_citizen2.get(CharacterMotionControl)).checkDirection = false; //do NPCs not have CharacterMotionControl?
			
			SceneUtil.addTimedEvent( this, new TimedEvent( 1, 1, removeVan ) );
		}
		
		private function initRadioDialog():void
		{
			_radioDialog.visible = true;
			_radioDialog.addEventListener("enterFrame", moveRadioDialog);
			_notesEmitter.stop();
			radioAudio.stop(SoundManager.MUSIC_PATH + "Techno_Jam_Filtered.mp3");
			CharUtils.setDirection(_youngPerson, true);
		}
		
		private function moveRadioDialog(e:Event):void
		{
			_radioDialog.scaleX = _radioDialog.scaleY += (1 - _radioDialog.scaleX)/8;
			_radioDialog.t += 0.05;
			_radioDialog.y = _radioDialog.startY + 3*Math.sin(_radioDialog.t);
		}
		
		private function moveRadio(e:Event):void
		{
			_radio.t += 0.2;
			_radio.y = _radio.startY + 4*Math.sin(_radio.t);
			if (_radio.y > _radio.startY) {
				_radio.y = _radio.startY;
			}
		}
		
		private function endRadioDialog():void
		{
			_radioDialog.visible = false;
			_radioDialog.removeEventListener("enterFrame", moveRadioDialog);
			_notesEmitter.start();
			radioAudio.play(SoundManager.MUSIC_PATH + "Techno_Jam_Filtered.mp3", true, SoundModifier.POSITION);
			CharUtils.setDirection(_youngPerson, false);
		}
		
		private function reachedYoungPerson(player:Entity, npc:Entity):void
		{
			/*
			CharUtils.setAnim(_youngPerson, Grief, false);
			initRadioDialog();
			CharUtils.autoMotionOn(_youngPerson, true);
			Dialog(_youngPerson.get(Dialog)).sayById("statement1");
			*/
			
			CharUtils.setAnim(_youngPerson, Stand);
			//CharUtils.autoMotionOn(_youngPerson);
			
			actionChain = new ActionChain( this );
			actionChain.lockInput = true;
			
			actionChain.addAction( new CallFunctionAction(initRadioDialog) );
			actionChain.addAction( new WaitAction(6) );
			//actionChain.addAction( new AnimationAction(_youngPerson, Grief, "", 52) );
			actionChain.addAction( new TalkAction(_youngPerson, "statement1") );
			//actionChain.addAction( new AnimationAction(_youngPerson, Stomp, "", 35) );
			actionChain.addAction( new WaitAction(1) );
			actionChain.addAction( new CallFunctionAction(endRadioDialog) );
			actionChain.addAction( new WaitAction(1) );
			actionChain.addAction( new TalkAction(_youngPerson, "statement2") );
			
			actionChain.execute();
		}
		
		private function doHookHint(hitId:String, entityId:String):void
		{
			//trying to stop player from continuing movement if their mouse was held down!!!
			//MotionControl(super.player.get(MotionControl)).inputActive = false;
			//MotionControl(super.player.get(MotionControl)).inputStateDown = false;
			//Navigation(super.player.get(Navigation)).active = false;
			//EntityUtils.freeze(super.player);
			MotionUtils.zeroMotion(super.player, "x");
			CharUtils.lockControls(super.player, true, true);
			
			actionChain = new ActionChain( this );
			actionChain.lockInput = true;
			//actionChain.lockPosition = true; //this locks the mouse position. don't want that
			
			//actionChain.addAction( new MoveAction(super.player, MovieClip(_animationsContainer).rope) );
			actionChain.addAction( new WaitAction(0.5) );
			actionChain.addAction( new AnimationAction(super.player, Think, "", 60) );
			actionChain.addAction( new TalkAction(super.player, "hookOutOfReach"));
			actionChain.addAction( new CallFunctionAction(restoreControl) );
			
			actionChain.execute();
		}
		
		private function restoreControl():void
		{
			CharUtils.lockControls(super.player, false, false);
			MotionUtils.zeroMotion(super.player);
		}
		
		/*private function enterNestZone(hitId:String, entityId:String):void
		{
		_inNestZone = true;
		super.shellApi.log(String(_inNestZone));
		}
		
		private function exitNestZone(hitId:String, entityId:String):void
		{
		_inNestZone = false;
		super.shellApi.log(String(_inNestZone));
		}*/
		
		private function useResistanceBand():void
		{
			actionChain = new ActionChain( this );
			actionChain.lockInput = true;
			
			actionChain.addAction( new MoveAction(super.player, MovieClip(_animationsContainer).rope) );
			actionChain.addAction( new WaitAction(0.2) );
			//actionChain.addAction( new AnimationAction(super.player, Stand, "", 15) );
			actionChain.addAction( new AnimationAction(super.player, Throw, "", 15) );
			actionChain.addAction( new CallFunctionAction(showRopeAnimation) );
			actionChain.addAction( new WaitAction(0.6) );
			//actionChain.addAction( new AnimationAction(super.player, Stand, "", 10) );
			
			actionChain.execute();
		}
		
		private function showRopeAnimation():void
		{
			CharUtils.setDirection(super.player, false);
			TimelineClip(_ropeEntity.get(TimelineClip)).mc.visible = true;
			Timeline(_ropeEntity.get(Timeline)).playing = true;
			_ropeHit.add(new Climb());
			
			super.shellApi.removeItem("resistanceBand");
			super.shellApi.completeEvent(virusEvents.USED_RESISTANCE_BAND);
			
			super.shellApi.triggerEvent("playWhooshSound");
		}
		
		private function enterBertZone(hitId:String, entityId:String):void
		{
			_inBertZone = true;
		}
		
		private function exitBertZone(hitId:String, entityId:String):void
		{
			_inBertZone = false;
		}
		
		private function showBertTalkingOnRadio(hitId:String, entityId:String):void
		{
			SceneUtil.lockInput(this, true);
			//MotionUtils.zeroMotion(super.player, "x");
			SceneUtil.setCameraTarget( this, _bertShell );
			CharUtils.lockControls(super.player, true, true);
			Dialog(_bertShell.get(Dialog)).sayById("radioTalk");
		}
		
		private function finishRadioTalk():void
		{
			SceneUtil.lockInput(this, false);
			SceneUtil.setCameraTarget( this, player );
			CharUtils.lockControls(super.player, false, false);
		}
		
		private function useShreddedDocuments():void
		{
			//force auto click on Bert
			var interaction:Interaction = _bertShell.get(Interaction);
			interaction.click.dispatch(_bertShell);
			
		}
		
		private function walkToBert(player:Entity, npc:Entity):void
		{
			
		}
		
		private function openShreddedDocumentsPopup():void
		{
			//open Bart's shredded document mini game
			_shreddedDocumentsPopup = super.addChildGroup(new BlueprintPopup(super.overlayContainer)) as BlueprintPopup;
			_shreddedDocumentsPopup.id = "blueprintPopup";
			_shreddedDocumentsPopup.bpFound.addOnce(assembledShreds);
		}
		
		private function assembledShreds():void
		{
			_shreddedDocumentsPopup.hide(true);
			super.unpause();
			Dialog(_bertShell.get(Dialog)).sayById("assembledShreds");
			SceneUtil.lockInput(this, true);
		}
		
		private function reopenShreds():void
		{
			_shreddedDocumentsPopup.hide(false);
			super.pause();
			_shreddedDocumentsPopup.unpause();
			SceneUtil.lockInput(this, false);
			_shreddedDocumentsPopup.popupRemoved.addOnce(finishedShreds);
		}
		
		private function finishedShreds():void
		{
			//super.shellApi.completeEvent(virusEvents.ASSEMBLED_SHREDS);
			super.shellApi.triggerEvent(virusEvents.ASSEMBLED_SHREDS, true);
			Dialog(_bertShell.get(Dialog)).sayCurrent();
			SceneUtil.lockInput(this, true);
		}
	}
}