package game.scenes.carnival.ringmastersTent{
	import com.greensock.easing.Linear;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	
	import game.components.entity.Dialog;
	import game.components.timeline.Timeline;
	import game.components.entity.character.part.SkinPart;
	import game.components.scene.SceneInteraction;
	import game.data.animation.entity.character.Dizzy;
	import game.data.animation.entity.character.FightStance;
	import game.data.animation.entity.character.KeyboardTyping;
	import game.data.animation.entity.character.Stand;
	import game.data.animation.entity.character.Stomp;
	import game.data.animation.entity.character.Sword;
	import game.data.animation.entity.character.Tossup;
	import game.data.animation.entity.character.Tremble;
	import game.scenes.carnival.CarnivalEvents;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.carnival.midwayNight.MidwayNight;
	import game.systems.actionChain.ActionChain;
	import game.systems.actionChain.actions.AnimationAction;
	import game.systems.actionChain.actions.CallFunctionAction;
	import game.systems.actionChain.actions.MoveAction;
	import game.systems.actionChain.actions.RemoveItemAction;
	import game.systems.actionChain.actions.SetSkinAction;
	import game.systems.actionChain.actions.TalkAction;
	import game.systems.actionChain.actions.TimelineAction;
	import game.systems.actionChain.actions.WaitAction;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	
	public class RingmastersTent extends PlatformerGameScene
	{
		
		private var _events:CarnivalEvents;
		
		
		public function RingmastersTent()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/carnival/ringmastersTent/";
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
			
			_edgar = super.getEntityById("edgar");
			_ringmaster = super.getEntityById("ringmaster");
			
			_man = super.getEntityById("man");
			_woman = super.getEntityById("woman");
			_bubby = super.getEntityById("bubby");
			_sissy = super.getEntityById("sissy");
			_junior = super.getEntityById("junior");
			_father = super.getEntityById("father");				
			
			//super.shellApi.completeEvent(_events.SET_NIGHT)	
			//super.shellApi.getItem(_events.SODIUM_THIOPENTAL)	
			//super.shellApi.removeEvent(_events.EDGAR_LUNGE)
			//super.shellApi.removeEvent(_events.ESCAPED_RINGMASTER_TENT)
			
			if (!super.shellApi.checkHasItem(_events.SODIUM_THIOPENTAL) && !this.shellApi.checkEvent(_events.EDGAR_LUNGE)){
				MovieClip(super._hitContainer).bgart_mc.hose_mc.visible = false;
				MovieClip(super._hitContainer).cage1.visible = false;
				MovieClip(super._hitContainer).cage2.visible = false;
				MovieClip(super._hitContainer).chairarm.visible = false;
				MovieClip(super._hitContainer).chair.visible = false;
				MovieClip(super._hitContainer).dynamicHit.visible = false;
				super.removeEntity( _man );
				super.removeEntity( _woman );
				super.removeEntity( _bubby );
				super.removeEntity( _sissy );
				super.removeEntity( _junior );
				super.removeEntity( _father );
				super.convertToBitmapSprite(super._hitContainer["bgart_mc"]);
				
				for (var i:Number=0;i<6;i++){
					MovieClip(super._hitContainer["mask"+i+"_mc"]).alpha = 0;
				}
			}else{
				super.convertToBitmapSprite(super._hitContainer["bgart_mc"], null, true);
				
				Display(_man.get(Display)).displayObject.mask = super._hitContainer["mask0_mc"];
				Display(_woman.get(Display)).displayObject.mask = super._hitContainer["mask1_mc"];
				Display(_bubby.get(Display)).displayObject.mask = super._hitContainer["mask2_mc"];
				Display(_sissy.get(Display)).displayObject.mask = super._hitContainer["mask3_mc"];
				Display(_junior.get(Display)).displayObject.mask = super._hitContainer["mask4_mc"];
				Display(_father.get(Display)).displayObject.mask = super._hitContainer["mask5_mc"];
				
				_man.get(SceneInteraction).reached.removeAll();
				_man.get(SceneInteraction).approach = false;
				_woman.get(SceneInteraction).reached.removeAll();
				_woman.get(SceneInteraction).approach = false;
				_bubby.get(SceneInteraction).reached.removeAll();
				_bubby.get(SceneInteraction).approach = false;
				_sissy.get(SceneInteraction).reached.removeAll();
				_sissy.get(SceneInteraction).approach = false;
				_junior.get(SceneInteraction).reached.removeAll();
				_junior.get(SceneInteraction).approach = false;
				_father.get(SceneInteraction).reached.removeAll();
				_father.get(SceneInteraction).approach = false;
			}			

			super.shellApi.eventTriggered.add(handleEventTriggered);
			
			TimelineUtils.convertClip(  MovieClip(super._hitContainer).cage1, this );
			TimelineUtils.convertClip(  MovieClip(super._hitContainer).cage2, this );
			TimelineUtils.convertClip(  MovieClip(super._hitContainer).bird1, this );
			TimelineUtils.convertClip(  MovieClip(super._hitContainer).lightrow0, this );
			TimelineUtils.convertClip(  MovieClip(super._hitContainer).lightrow1, this );
			TimelineUtils.convertClip(  MovieClip(super._hitContainer).lightrow2, this );
			TimelineUtils.convertClip(  MovieClip(super._hitContainer).lightrow3, this );
			TimelineUtils.convertClip(  MovieClip(super._hitContainer).lightrow4, this );
			TimelineUtils.convertClip(  MovieClip(super._hitContainer).lightrow5, this );
			TimelineUtils.convertClip(  MovieClip(super._hitContainer).lightrow6, this );
			TimelineUtils.convertClip(  MovieClip(super._hitContainer).Spotlight0, this );
			TimelineUtils.convertClip(  MovieClip(super._hitContainer).Spotlight1, this );
			TimelineUtils.convertClip(  MovieClip(super._hitContainer).Spotlight2, this );
			TimelineUtils.convertClip(  MovieClip(super._hitContainer).Spotlight3, this );
			TimelineUtils.convertClip(  MovieClip(super._hitContainer).lights_mc, this );					
			
			_controls = EntityUtils.createSpatialEntity( this, MovieClip( MovieClip(super._hitContainer).controls_mc ) );
			TimelineUtils.convertClip( MovieClip( MovieClip(super._hitContainer).controls_mc ), this, _controls, null, false );
			Timeline(_controls.get(Timeline)).gotoAndStop("starting");	
			_controls.get(Timeline).handleLabel( "Activating", machineOn, false  );
			_controls.get(Timeline).handleLabel( "activated", machineHum, false  );
			_controls.get(Timeline).handleLabel( "deactivate", machineOff, false  );
			_controls.get(Timeline).handleLabel( "deactivated", powerDown, false );	
			
			_bird = EntityUtils.createSpatialEntity( this, MovieClip( MovieClip(super._hitContainer).bird_mc ) );
			TimelineUtils.convertClip( MovieClip( MovieClip(super._hitContainer).bird_mc ), this, _bird, null, false );
			Timeline(_bird.get(Timeline)).gotoAndStop(1);
			_bird.get(Timeline).handleLabel( "birdcaw", birdCaw, false  );
			_bird.get(Timeline).handleLabel( "revup", revUp, false  );
			_bird.get(Timeline).handleLabel( "poweroff", powerOff, false  );
			_bird.get(Timeline).handleLabel( "loop", loopBird, false );
			
			_birdback = EntityUtils.createSpatialEntity( this, MovieClip( MovieClip(super._hitContainer).birdback_mc ) );
			TimelineUtils.convertClip( MovieClip( MovieClip(super._hitContainer).birdback_mc ), this, _birdback, null, false );
			Timeline(_birdback.get(Timeline)).gotoAndStop(1);					
			
			super._hitContainer.setChildIndex ( MovieClip(super._hitContainer).overlay_mc, (super._hitContainer.numChildren - 1));	
			_overlay =  EntityUtils.createSpatialEntity( this, MovieClip( MovieClip(super._hitContainer).overlay_mc ) );
			_overlay.get(Display).alpha = 0;
			
			_birdSoundEntity = AudioUtils.createSoundEntity("_birdSoundEntity");	
			_birdAudio = new Audio();
			_birdSoundEntity.add(_birdAudio);			
			super.addEntity(_birdSoundEntity);			
			
			_machineSoundEntity = AudioUtils.createSoundEntity("_machineSoundEntity");	
			_machineAudio = new Audio();
			_machineSoundEntity.add(_machineAudio);			
			super.addEntity(_machineSoundEntity);		
			
			_backgroundSoundEntity = AudioUtils.createSoundEntity("_backgroundSoundEntity");	
			_backgroundAudio = new Audio();
			_backgroundSoundEntity.add(_backgroundAudio);			
			super.addEntity(_backgroundSoundEntity);	
			
			
			
			SkinUtils.setSkinPart( player, SkinUtils.MOUTH, "2" );					
			
			if (this.shellApi.checkEvent(_events.SET_NIGHT)){
				_backgroundAudio.play(SoundManager.MUSIC_PATH + "carnival_night.mp3", true);
				if (this.shellApi.checkEvent(_events.EDGAR_RAN_TENT) && !this.shellApi.checkEvent(_events.SPOKE_RINGMASTER_FORMULA)){
					_edgar.get(Spatial).x = 1500;
					_edgar.get(Spatial).y = 1300;
					CharUtils.moveToTarget(player, 1600, 1330, false, startTalk);	
					SkinUtils.setSkinPart( _edgar, SkinUtils.EYES, "eyes" );
					SkinUtils.setSkinPart (_edgar, SkinUtils.MOUTH, "sponsor_ramona");	
					SkinUtils.setSkinPart (_edgar, SkinUtils.MARKS, SkinPart.EMPTY);	
					SkinUtils.setSkinPart( _ringmaster, SkinUtils.EYES, "eyes" );
					lockControl();					
				}else{
					var ringmasterInteraction:SceneInteraction = _ringmaster.get(SceneInteraction);
					ringmasterInteraction.reached.removeAll();
					ringmasterInteraction.approach = false;
					
					var edgarInteraction:SceneInteraction = _edgar.get(SceneInteraction);
					edgarInteraction.reached.removeAll();
					edgarInteraction.approach = false;		
					
					if (this.shellApi.checkEvent(_events.EDGAR_LUNGE) && !this.shellApi.checkEvent(_events.ESCAPED_RINGMASTER_TENT)){
						setupChair();	
					}else if (super.shellApi.checkHasItem(_events.SODIUM_THIOPENTAL) && !this.shellApi.checkEvent(_events.ESCAPED_RINGMASTER_TENT)){
						_edgar.get(Spatial).x = 300;
						_edgar.get(Spatial).y = 1330;
						player.get(Spatial).x = 400;
						player.get(Spatial).y = 1330;
						movePlayers();		
					}else{
						super.removeEntity( _ringmaster );
						super.removeEntity( _edgar );
						super.convertToBitmapSprite(super._hitContainer["bird_mc"]);
						super.convertToBitmapSprite(super._hitContainer["birdback_mc"]);
					}
				}
			}else{				
				super.removeEntity( _edgar );
				super.convertToBitmapSprite(super._hitContainer["bird_mc"]);
				super.convertToBitmapSprite(super._hitContainer["birdback_mc"]);
				SkinUtils.setSkinPart( _ringmaster, SkinUtils.EYES, "eyes" );
				_backgroundAudio.play(SoundManager.MUSIC_PATH + "ringmasters_tent.mp3", true);
			}
			
		}
		
		private function handleEventTriggered(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			switch(event){
				case "useDough":	
					if (_useDough == true) continueLockup();
				break;
			}
		}
		
		private function startTalk(...args):void{
			
			var actChain:ActionChain = new ActionChain( this );
			actChain.lockInput = true;	
			
			actChain.addAction( new TalkAction( _edgar, "turnedMonsters" ) );
			actChain.addAction( new TalkAction( _ringmaster, "knowNeed" ) );					
			actChain.addAction( new TalkAction( player, "whereFormula" ) );	
			actChain.addAction( new TalkAction( _ringmaster, "ferrisMonster" ) );
			actChain.addAction( new TalkAction( _edgar, "toWheel" ) );
			actChain.addAction( new MoveAction( _edgar, new Point( 400, 1330 ) ) );
			actChain.execute(this.finishTalk);	

		}
		
		private function finishTalk(...args):void{
			super.removeEntity( _edgar );
			super.shellApi.triggerEvent(_events.SPOKE_RINGMASTER_FORMULA, true)
			restoreControl();
			
	
			var ringmasterInteraction:SceneInteraction = _ringmaster.get(SceneInteraction);
			ringmasterInteraction.reached.removeAll();
			ringmasterInteraction.reached.add(ringmasterClicked);	
		}
		
		private function ringmasterClicked(...args):void{
			
			Dialog(_ringmaster.get(Dialog)).sayById("hurryFerris");
		}
		
		private function movePlayers(...args):void{
			
			CharUtils.moveToTarget(player, 1600, 1335, false, startGrab);	
			CharUtils.moveToTarget(_edgar, 1500, 1335, false);
			
			lockControl();
		}			
		
		private function startGrab(...args):void{
			
			var actChain:ActionChain = new ActionChain( this );
			actChain.lockInput = true;	
			
			actChain.addAction( new TalkAction( _edgar, "broughtCompound" ) );
			actChain.addAction( new TalkAction( player, "questionMaster" ) );					
			actChain.addAction( new SetSkinAction( player, SkinUtils.MOUTH, "distressedMom", true ) );	
			actChain.addAction( new TalkAction( _ringmaster, "seizeHim" ) );
			actChain.addAction( new MoveAction( _edgar, new Point( player.get(Spatial).x-40, 1335 ) ) );
			actChain.addAction( new CallFunctionAction(playerTremble));
			actChain.execute(this.seizePlayer);	
			
			lockControl();
		}		
		
		private function seizePlayer(...args):void{
			
			super.shellApi.triggerEvent( _events.EDGAR_LUNGE, true );
			TweenUtils.entityTo(_overlay, Display, .5,{alpha:1, ease:Linear.easeIn, onComplete:setupChair}, '' ,.25);
			//this.shellApi.loadScene(RingmastersTent,1705,798,"right");
		}
		
		private function setupChair(...args):void{		

			super._hitContainer.setChildIndex ( MovieClip(super._hitContainer).chairarm, (super._hitContainer.numChildren - 1));
			super._hitContainer.setChildIndex ( _edgar.get(Display).displayObject, (super._hitContainer.numChildren - 1));
			super._hitContainer.setChildIndex ( _ringmaster.get(Display).displayObject, (super._hitContainer.numChildren - 1));
			super._hitContainer.setChildIndex ( _bird.get(Display).displayObject, (super._hitContainer.numChildren - 1));
			super._hitContainer.setChildIndex ( MovieClip(super._hitContainer).lights_mc, (super._hitContainer.numChildren - 1));
			super._hitContainer.setChildIndex ( _overlay.get(Display).displayObject, (super._hitContainer.numChildren - 1));
				
			CharUtils.setAnim(player, Dizzy);
			SkinUtils.setSkinPart( player, SkinUtils.MOUTH, "distressedMom" );
			SkinUtils.setSkinPart( player, SkinUtils.EYE_STATE, "open" );
			player.get(Spatial).x = 1712;
			player.get(Spatial).y = 800;			
			_edgar.get(Spatial).x = 1600;
			_edgar.get(Spatial).y = 860;				
			_ringmaster.get(Spatial).x = 1800;
			_ringmaster.get(Spatial).y = 860;	
			
			TweenUtils.entityTo(_overlay, Display, 1,{alpha:0, ease:Linear.easeIn, onComplete:startLockup}, '', 1.5);
			lockControl();			
		}

		private function playerTremble(...args):void{
			CharUtils.setAnim(_edgar, FightStance);	
			CharUtils.setAnim(_ringmaster, Stomp);		
			CharUtils.setAnim(player, Tremble);	
			CharUtils.setAnim(_edgar, Sword);		
		}
		
		private function giveClickControl(...args):void{
			SceneUtil.lockInput(this, false);
			_useDough = true;
		}
		
		private function startLockup(...args):void{
			var action:AnimationAction;
			var actChain:ActionChain = new ActionChain( this );
			actChain.lockInput = true;			
			
			actChain.addAction( new SetSkinAction( player, SkinUtils.EYE_STATE, "open", true ) );	
			actChain.addAction( new SetSkinAction( player, SkinUtils.MOUTH, "distressedMom", true ) );				
			actChain.addAction( new AnimationAction(  _ringmaster, Tossup, "end" ) );			
			actChain.addAction( new SetSkinAction( _ringmaster, SkinUtils.FACIAL, "mc_raven", true ) );	
			actChain.addAction( new WaitAction( 1 ) );	
			actChain.addAction( new RemoveItemAction( _events.SODIUM_THIOPENTAL, "ringmaster" ) );	
			actChain.addAction( new TalkAction( _ringmaster, "confirmMaster" ) );
			actChain.addAction( new TalkAction( player, "whyHypnotize" ) );
			actChain.addAction( new TalkAction( _ringmaster, "forRevenge" ) );
			actChain.addAction( new TalkAction( player, "yourWrong" ) );
			actChain.addAction( new TalkAction( _ringmaster, "takeOver" ) );
			actChain.addAction( new TalkAction( player, "screamNo" ) );
			actChain.addAction( new TalkAction( _ringmaster, "letsBegin" ) );
			actChain.addAction( new MoveAction( _ringmaster, new Point( 870, 1000 ) ) );
			actChain.addAction( new MoveAction( _edgar, new Point( 1530, 870 ) ) );
			actChain.addAction( new AnimationAction( _edgar, KeyboardTyping, "end" ) );			
			actChain.addAction( new TimelineAction( _controls, "Activating", "activated" ) );			
			actChain.addAction( new CallFunctionAction(powerUp));
			actChain.addAction( new MoveAction( _edgar, new Point( 1950, 870 ), null, -1 ) );
			actChain.addAction( new TalkAction( player, "edgarApproach" ) );
			
			actChain.execute(this.giveClickControl);
			lockControl();		
		}
		
		private function continueLockup(...args):void{
			var action:AnimationAction;
			var actChain:ActionChain = new ActionChain( this );
			actChain.lockInput = true;			
			
			actChain.addAction( new RemoveItemAction( _events.FRIED_DOUGH, "edgar" ) );
			actChain.addAction( new SetSkinAction( _edgar, SkinUtils.EYES, "eyes", true ) );	
			actChain.addAction( new SetSkinAction( _edgar, SkinUtils.MARKS, SkinPart.EMPTY, true ) );	
			actChain.addAction( new SetSkinAction( _edgar, SkinUtils.MOUTH, 'sponsor_ramona', true ) );				
			actChain.addAction( new TalkAction( _edgar, "gotFriedDough" ) );
			actChain.addAction( new TalkAction( player, "whatHappened" ) );
			actChain.addAction( new MoveAction( _edgar, new Point( 1530, 870 ) ) );
			actChain.addAction( new AnimationAction( _edgar, KeyboardTyping, "end" ) );			
			actChain.addAction( new TimelineAction( _controls, "deactivate", "deactivated" ) );
			actChain.addAction( new SetSkinAction( player, SkinUtils.MOUTH, "2", true ) );	
			actChain.addAction( new AnimationAction(  player, Stand, "loop" ) );
			actChain.addAction( new MoveAction( player, new Point( 1760, 860 ), null, -1 ) );				
			actChain.addAction( new TalkAction( _edgar, "edgarHypnotized" ) );
			actChain.addAction( new CallFunctionAction(showRingmaster));
			actChain.addAction( new TalkAction( _ringmaster, "stopRingmaster" ) );
			actChain.addAction( new MoveAction( _ringmaster, new Point( 385, 1330 ) ) );
			
			actChain.execute(this.removeRingmaster);
			lockControl();		
		}
		
		
		private function machineOn(...args):void{
			super.shellApi.triggerEvent("machineOn");
		}
		private function machineHum(...args):void{
			_birdAudio.play(SoundManager.EFFECTS_PATH + "power_on_06.mp3", true);			
		}
		private function machineOff(...args):void{
			trace("machineoff")
			super.shellApi.triggerEvent("machineOff");
			_birdAudio.stop(SoundManager.EFFECTS_PATH + "power_on_06.mp3");
		}
		private function birdCaw(...args):void{
			super.shellApi.triggerEvent("machineCaw");
		}
		private function revUp(...args):void{
			_machineAudio.play(SoundManager.EFFECTS_PATH + "electric_buzz_03_loop.mp3", true);
		}		
		private function powerOff(...args):void{
			trace("poweroff")
			_machineAudio.stop(SoundManager.EFFECTS_PATH + "electric_buzz_03_loop.mp3");
			Timeline(_birdback.get(Timeline)).gotoAndStop("off");
			Timeline(_bird.get(Timeline)).gotoAndStop("off");
		}
		
		private function loopBird(...args):void{
			Timeline(_birdback.get(Timeline)).gotoAndPlay("idle");	
			Timeline(_bird.get(Timeline)).gotoAndPlay("idle");	
		}
		
		private function powerDown(...args):void{
			Timeline(_controls.get(Timeline)).gotoAndStop("starting");	
			Timeline(_bird.get(Timeline)).gotoAndPlay("powerdown");	
			Timeline(_birdback.get(Timeline)).gotoAndPlay("powerdown");	
			_backgroundAudio.stop(SoundManager.MUSIC_PATH + "catastrophicevent.mp3");
			_backgroundAudio.play(SoundManager.MUSIC_PATH + "carnival_night.mp3", true);
		}
		
		private function powerUp(...args):void{
			Timeline(_controls.get(Timeline)).stop();
			Timeline(_bird.get(Timeline)).gotoAndPlay("powerup");	
			Timeline(_birdback.get(Timeline)).gotoAndPlay("powerup");	
			_backgroundAudio.stop(SoundManager.MUSIC_PATH + "carnival_night.mp3");
			_backgroundAudio.play(SoundManager.MUSIC_PATH + "catastrophicevent.mp3", true);			
		}
		
		private function showRingmaster(...args):void{
			SceneUtil.setCameraTarget(this, _ringmaster);
		}		
		
		private function removeRingmaster(...args):void{
			MovieClip(super._hitContainer).chairarm.visible = false;
			super.shellApi.triggerEvent(_events.ESCAPED_RINGMASTER_TENT, true);
			super.removeEntity( _ringmaster );			
			SceneUtil.setCameraTarget( this, player );
			CharUtils.moveToTarget(player, 400, 1330, false, leaveTent);	
			lockControl();		
		}
		
		private function leaveTent(...args):void
		{
			this.shellApi.loadScene(MidwayNight, 4378, 1800 );
			restoreControl();
		}
				
		private function lockControl(...args):void
		{
			MotionUtils.zeroMotion(super.player, "x");
			CharUtils.lockControls(super.player, true, true);
			SceneUtil.lockInput(this, true);
		}
		
		private function restoreControl(...args):void
		{
			CharUtils.lockControls(super.player, false, false);
			MotionUtils.zeroMotion(super.player);
			SceneUtil.lockInput(this, false);
		}
		
		private var _edgar:Entity;
		private var _ringmaster:Entity;
		private var _controls:Entity;
		private var _bird:Entity;
		private var _birdback:Entity;
		private var _overlay:Entity;
		private var _birdSoundEntity:Entity;
		private var _birdAudio:Audio;
		private var _machineSoundEntity:Entity;
		private var _machineAudio:Audio;
		private var _backgroundSoundEntity:Entity;
		private var _backgroundAudio:Audio;
		private var _useDough:Boolean = false;
		private var _man:Entity;
		private var _woman:Entity;
		private var _bubby:Entity;
		private var _sissy:Entity;
		private var _father:Entity;
		private var _junior:Entity;
	}
}










