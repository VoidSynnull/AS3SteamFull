package game.scenes.mocktropica.classroom{
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	
	import game.components.entity.Dialog;
	import game.components.motion.Threshold;
	import game.components.scene.SceneInteraction;
	import game.components.hit.Zone;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Grief;
	import game.data.animation.entity.character.Stand;
	import game.data.animation.entity.character.Stomp;
	import game.scenes.mocktropica.MocktropicaEvents;
	import game.data.sound.SoundModifier;
	import game.scenes.mocktropica.classroom.PoemPopup;
	import game.scenes.mocktropica.shared.*;
	import game.systems.actionChain.ActionChain;
	import game.systems.actionChain.actions.MoveAction;
	import game.systems.actionChain.actions.RemoveItemAction;
	import game.systems.actionChain.actions.TalkAction;
	import game.systems.motion.BoundsCheckSystem;
	import game.systems.SystemPriorities;
	import game.systems.motion.ThresholdSystem;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.SceneUtil;

	
	public class Classroom extends MocktropicaScene
	{
		public function Classroom()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/mocktropica/classroom/";
			
			//super.showHits = true;
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
			
			_leadWriter = super.getEntityById("leadWriter");
			_student1 = super.getEntityById("student1");
			_student2 = super.getEntityById("student2");
			
			super.shellApi.eventTriggered.add(handleEventTriggered);	
			super.addSystem(new BoundsCheckSystem(), SystemPriorities.resolveCollisions);
			
			var writerSpeakZone:Zone;
			_writerSpeakZoneEntity = super.getEntityById( "writerSpeakZone" );
			
			var ballHitZone:Zone;
			_ballHitZoneEntity = super.getEntityById( "ballHitZone" );
			ballHitZone = _ballHitZoneEntity.get( Zone );
			ballHitZone.pointHit = true;
			ballHitZone.entered.add(doBallHit);
			
			createMovingBall();
			
			var writerInteraction:SceneInteraction;
			
			if(!this.shellApi.checkEvent(_events.POEM_GIVEN))
			{				
				writerSpeakZone = _writerSpeakZoneEntity.get( Zone );
				writerSpeakZone.pointHit = true;
				writerSpeakZone.entered.addOnce(doWriterSpeak);
			}
			else if(this.shellApi.checkEvent(_events.POEM_GIVEN) && !this.shellApi.checkEvent(_events.COMPLETED_POPUPAD2))
			{				
				writerInteraction = _leadWriter.get(SceneInteraction);
				writerInteraction.reached.removeAll();
				writerInteraction.reached.add(doPopup);	
			}
			else if(!this.shellApi.checkEvent(_events.WRITER_LEFT_CLASSROOM))
			{
				writerInteraction = _leadWriter.get(SceneInteraction);
				writerInteraction.reached.removeAll();
				writerInteraction.reached.add(writerClicked);
			}
			
			setUpRadio();
			
			//only if not started bonus quest - needs check added
			if ( super.shellApi.sceneManager.previousScene == "game.scenes.mocktropica.megaFightingBots::MegaFightingBots"){				
				super.shellApi.triggerEvent("lostMegaFightingBots");
			}
			
			_adGroup = super.addChildGroup( new AdvertisementGroup( this, super.overlayContainer )) as AdvertisementGroup;
			
			this.setupSittingStudents();
			
			_poemCreated = false;
			
		}
		
		private function setUpRadio():void
		{
			radioSoundEntity = new Entity();
			radioAudio = new Audio();
			radioAudio.play(SoundManager.MUSIC_PATH + "MFB_Classroom_Game_filtered.mp3", true, [SoundModifier.POSITION, SoundModifier.EFFECTS]);
			radioSoundEntity.add(radioAudio);
			radioSoundEntity.add(new Spatial(1237, 435));
			radioSoundEntity.add(new AudioRange(400, 0, 1, Quad.easeIn));
			radioSoundEntity.add(new Id("soundSource"));
			super.addEntity(radioSoundEntity);
		}
		
		
		private function createMovingBall():void{
			_ballEntity = EntityUtils.createMovingEntity(this, MovieClip(super._hitContainer).paperBall, super._hitContainer);			
			var boundsRect:Rectangle = new Rectangle(40, 40, 1840, 615);
			var motionBounds:MotionBounds = new MotionBounds(boundsRect);
			_ballEntity.add(motionBounds);
		}
		
		private function doBallHit(hitId:String, entityId:String):void
		{			
			
			super.shellApi.triggerEvent("paperHitSFX");
			
			var degree:Number = 45;
			var speed:Number = 1000;
			var vx:Number = player.get(Motion).velocity.x;
			
			if (vx > 0)	degree = 45; else degree = 315;			
			speed = Math.abs(vx) + 200;

			var radians:Number = degree * Math.PI / 180;
			var xSpeed:Number = speed *  Math.sin(radians);
			var ySpeed:Number = (0 - speed) * Math.cos(radians);				
			
			var motion:Motion = _ballEntity.get(Motion);
			motion.velocity.x = xSpeed;
			motion.velocity.y = ySpeed;
			motion.acceleration.y = MotionUtils.GRAVITY;
			
			super.addSystem( new ThresholdSystem() );
			var thresholdy:Threshold = new Threshold( "y", ">" )
			thresholdy.threshold = 565;
			thresholdy.entered.add( ballLanded );
			_ballEntity.add( thresholdy );
						
			MovieClip(super._hitContainer).ballHitZone.y = 2000;
		}
		
		
		public function ballLanded():void{
			
			super.shellApi.triggerEvent("paperHitSFX");
			var lx:Number = _ballEntity.get(Spatial).x;
			
			super.removeEntity( _ballEntity )
			
			createMovingBall();
			
			_ballEntity.get(Spatial).y = 565;
			_ballEntity.get(Spatial).x = lx;
			
			MovieClip(super._hitContainer).ballHitZone.x = lx;
			MovieClip(super._hitContainer).ballHitZone.y = 575;

		}
		
		
			
		private function writerClicked(player:Entity, npc:Entity):void{
			if(!this.shellApi.checkEvent(_events.WRITER_ASKED_SODA)){
				Dialog(_leadWriter.get(Dialog)).sayById("onlyPoem");
				lockControl();
				super.shellApi.camera.target = _leadWriter.get(Spatial);
			}else if(super.shellApi.checkHasItem(_events.POP) && this.shellApi.checkEvent(_events.WRITER_ASKED_SODA)){
				super.shellApi.triggerEvent("givePop");
			}else if(this.shellApi.checkEvent(_events.WRITER_ASKED_SODA) && !this.shellApi.checkEvent(_events.GAVE_WRITER_SODA)){
				Dialog(_leadWriter.get(Dialog)).sayById("wantSoda");
			} else if(super.shellApi.checkHasItem(_events.SCRIPT) && this.shellApi.checkEvent(_events.WRITER_ASKED_SCRIPT)){
				super.shellApi.triggerEvent("giveScript");
			}else if(this.shellApi.checkEvent(_events.WRITER_ASKED_SCRIPT) && !this.shellApi.checkEvent(_events.WRITER_LEFT_CLASSROOM)){
				Dialog(_leadWriter.get(Dialog)).sayById("wantScript");
			}
		}
		
		private function setupSittingStudents():void
		{
			/**
			 * 3 students are sitting, so to better position them in their seats with the Sit animation,
			 * the last 3 students are being rotated slightly.
			 */
			for(var i:int = 3; i <= 5; i++)
			{
				var student:Entity = this.getEntityById("student" + i);
				var spatial:Spatial = student.get(Spatial);
				spatial.rotation += 15;
				Dialog(student.get(Dialog)).faceSpeaker = false;
			}
		}
		
		
		private function doWriterSpeak(hitId:String, entityId:String):void
		{
			lockControl();
			Dialog(_leadWriter.get(Dialog)).sayById("studyPoem");
			Dialog(_leadWriter.get(Dialog)).faceSpeaker = false;
			super.shellApi.camera.target = _student1.get(Spatial);
			radioAudio.setVolume(0);
		}

		
		private function showPopup():void {
			_poemPop = super.addChildGroup( new PoemPopup( super.overlayContainer )) as PoemPopup;		
			_adGroup.createAdvertisement( _events.ADVERTISEMENT_BOSS_2, completeAds);
			//super.addChildGroup( new AdvertisementGroup( this, super.overlayContainer )) as AdvertisementGroup;
			_poemCreated = true;
		}
		
		private function doPopup(player:Entity, npc:Entity):void{
			Dialog(_leadWriter.get(Dialog)).sayById("classicPoem");
			lockControl();
		}

		private function completeAds( ...args ):void
		{
			// a hook for after the popup is finished to add scene code into
			super.shellApi.triggerEvent( _events.COMPLETED_POPUPAD2, true );
			Dialog(_leadWriter.get(Dialog)).sayById("onlyPoem");			
			
			var writerInteraction:SceneInteraction = _leadWriter.get(SceneInteraction);
			writerInteraction.reached.removeAll();
			writerInteraction.reached.add(writerClicked);
			
			_poemPop.close();
			_poemCreated = false;
			lockControl();
		}
		
		private function handleEventTriggered(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			switch(event){
				case "givePoem":
					super.shellApi.triggerEvent( _events.POEM_GIVEN, true );
					showPopup();
					restoreControl();
					radioAudio.setVolume(1);
				break;
				case "turnBackStudent":
					Dialog(_student1.get(Dialog)).faceSpeaker = false;
					CharUtils.setDirection(_student1, true);					
				break;
				case "doneBickering":
					CharUtils.setAnim(_student1,Grief);
					CharUtils.setAnim(_student2,Stomp);					
					SceneUtil.addTimedEvent( this, new TimedEvent( 1, 1, finishTumble ));
				break;
				case "askedForSoda":
					super.shellApi.triggerEvent( _events.WRITER_ASKED_SODA, true );					
				break;
				case "searchingSoda":
					restoreControl();
					super.shellApi.camera.target = super.player.get(Spatial);
				break;
				case "givePop":					
					giveWriterSoda();
				break;
				case "askedForScript":					
					super.shellApi.triggerEvent( _events.WRITER_ASKED_SCRIPT, true );
					restoreControl();
				break;
				case "giveScript":						
					giveWriterScript();					
				break;
				case "captainChant":						
					Dialog(_leadWriter.get(Dialog)).faceSpeaker = false;
					CharUtils.setDirection(_leadWriter, true);				
				break;
				case "writerLeaveScene":
					radioAudio.setVolume(1);
					CharUtils.moveToTarget(_leadWriter, 195, 570, false, finishLeave);
					super.shellApi.triggerEvent( _events.WRITER_LEFT_CLASSROOM, true );
					//SceneUtil.addTimedEvent( this, new TimedEvent( 1, 1, finishLeave ));
				break;
				case _events.START_POPUP_BURN:
					if (_poemCreated) _poemPop.doBurn();
				break;
				
			}
			
		}
		
		private function giveWriterSoda():void 
		{			
			var actChain:ActionChain = new ActionChain( this );
			actChain.lockInput = true;
			
			// Because this triggers more talk actions...
			actChain.addAction( new MoveAction( player, new Point( _leadWriter.get(Spatial).x - 150, 570 ) ) );
			actChain.addAction( new RemoveItemAction( _events.POP, "leadWriter" ) );
			
			actChain.execute(this.gaveBackSoda);			
			lockControl();
		} //
		
		private function gaveBackSoda( chain:ActionChain ):void 
		{			
			Dialog(_leadWriter.get(Dialog)).sayById("sodaNotEnough");
			super.shellApi.removeItem(_events.POP);
			super.shellApi.triggerEvent( _events.GAVE_WRITER_SODA, true );
			lockControl();
			
		} //
		
		private function giveWriterScript():void
		{						
			var actChain:ActionChain = new ActionChain( this );
			actChain.lockInput = true;
			
			// Because this triggers more talk actions...
			actChain.addAction( new MoveAction( player, new Point( _leadWriter.get(Spatial).x - 150, 570 ) ) );
			actChain.addAction( new RemoveItemAction( _events.SCRIPT, "leadWriter" ) );
			actChain.addAction( new TalkAction( _leadWriter, "givenScript" ) );
			actChain.addAction( new RemoveItemAction( _events.WRITER_ID, "leadWriter" ) );
			
			actChain.execute( this.gaveBackBadge );		
			lockControl();
			
		} //
		
		
		private function gaveBackBadge( chain:ActionChain ):void
		{			
			//this.achievements.completeAchievement( this.mockEvents.ACHIEVEMENT_CURD_BURGLAR );
			super.shellApi.camera.target = _student1.get(Spatial);
			Dialog(_student1.get(Dialog)).sayById("chantStart");
			super.shellApi.removeItem(_events.SCRIPT);
			super.shellApi.removeItem(_events.WRITER_ID);
			lockControl();
			radioAudio.setVolume(0);
			
		} //
		
		private function finishLeave(...args):void
		{			
			super.shellApi.camera.target = super.player.get(Spatial);
			super.removeEntity( _leadWriter );
			restoreControl();
		}
		
		private function finishTumble():void
		{
			super.shellApi.camera.target = super.player.get(Spatial);
			Dialog(_leadWriter.get(Dialog)).sayById("changeLives");
			Dialog(_leadWriter.get(Dialog)).faceSpeaker = true;
			CharUtils.setAnim(_student1,Stand);
			CharUtils.setAnim(_student2,Stand);
		}
		
		private function lockControl():void
		{
			MotionUtils.zeroMotion(super.player, "x");
			CharUtils.lockControls(super.player, true, true);
			SceneUtil.lockInput(this, true);
		}
		
		private function restoreControl():void
		{
			CharUtils.lockControls(super.player, false, false);
			MotionUtils.zeroMotion(super.player);
			SceneUtil.lockInput(this, false);
		}
		
		
		private var _leadWriter:Entity;
		private var _student1:Entity;
		private var _student2:Entity;
		private var _writerSpeakZoneEntity:Entity;
		private var _ballHitZoneEntity:Entity;
		private var _events:MocktropicaEvents;
		private var _ballEntity:Entity;
		private var radioSoundEntity:Entity;
		private var radioAudio:Audio;
		private var _adGroup:AdvertisementGroup;
		private var _poemPop:PoemPopup;
		private var _poemCreated:Boolean;
	}
}