package game.scenes.mocktropica.cheeseInterior {
	
	import com.greensock.TweenLite;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.data.AudioWrapper;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.VariableTimeline;
	import game.components.entity.character.part.SkinPart;
	import game.components.hit.Mover;
	import game.components.hit.Zone;
	import game.components.motion.Proximity;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.animation.entity.character.Attack;
	import game.data.animation.entity.character.Grief;
	import game.data.animation.entity.character.Throw;
	import game.data.scene.characterDialog.DialogData;
	import game.scenes.mocktropica.MocktropicaEvents;
	import game.scenes.mocktropica.basement.Basement;
	import game.scenes.mocktropica.cheeseInterior.components.CheeseMachine;
	import game.scenes.mocktropica.cheeseInterior.components.ScreenShake;
	import game.scenes.mocktropica.cheeseInterior.components.ValueMatch;
	import game.scenes.mocktropica.cheeseInterior.components.Wheel;
	import game.scenes.mocktropica.cheeseInterior.components.WheelTarget;
	import game.scenes.mocktropica.cheeseInterior.systems.CheeseMachineSystem;
	import game.scenes.mocktropica.cheeseInterior.systems.ScreenShakeSystem;
	import game.scenes.mocktropica.cheeseInterior.systems.ValueMatchSystem;
	import game.scenes.mocktropica.cheeseInterior.systems.VariableTimelineSystem;
	import game.scenes.mocktropica.cheeseInterior.systems.WheelTargetSystem;
	import game.scenes.mocktropica.cheeseInterior.systems.WheelUpdateSystem;
	import game.scenes.mocktropica.shared.AchievementGroup;
	import game.scenes.mocktropica.shared.MocktropicaScene;
	import game.scenes.time.greece2.components.SmokeWisp;
	import game.scenes.time.greece2.components.smokePoint;
	import game.scenes.time.greece2.systems.SmokeWispSystem;
	import game.scenes.virusHunter.condoInterior.classes.DropletEmitter;
	import game.scenes.virusHunter.joesCondo.util.ClipUtils;
	import game.systems.SystemPriorities;
	import game.systems.actionChain.ActionChain;
	import game.systems.actionChain.ActionCommand;
	import game.systems.actionChain.actions.AnimationAction;
	import game.systems.actionChain.actions.CallFunctionAction;
	import game.systems.actionChain.actions.GetItemAction;
	import game.systems.actionChain.actions.MoveAction;
	import game.systems.actionChain.actions.PanAction;
	import game.systems.actionChain.actions.RemoveItemAction;
	import game.systems.actionChain.actions.SetSkinAction;
	import game.systems.actionChain.actions.TalkAction;
	import game.systems.actionChain.actions.WaitSignalAction;
	import game.systems.motion.ProximitySystem;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	
	public class CheeseInterior extends MocktropicaScene {
		
		private const WHEEL_OFF_ANGLE:Number = 0;
		private const WHEEL_ON_ANGLE:Number = 100*Math.PI/180;
		
		private const MACHINE_DIAL_MIN:Number = 1290;
		private const MACHINE_DIAL_MAX:Number = 1334;
		
		private const MIN_MACHINE_SPEED:Number = 1;
		private const MEDIUM_MACHINE_SPEED:Number = 3;
		private const MAX_MACHINE_SPEED:Number = 6;
		
		/**
		 * The factor conveyer belt with all its appertenances.
		 */
		private var conveyer:Entity;
		
		/**
		 * Wheely crank thing.
		 */
		private var wheel:Entity;
		
		/**
		 * Dial that indicates machine speed.
		 */
		private var indicator:Entity;
		private var cheeseMachine:Entity;
		
		// Poptropica designer.
		private var designer:Entity;
		
		// Movieclip of the destroyed cheese machine.
		private var destroyedMachineClip:MovieClip;
		
		// Indicates the player broke the machine.
		private var brokeMachine:Boolean = false;
		
		private var mockEvents:MocktropicaEvents;
		
		/**
		 * Used for fade-in/fade-out
		 */
		private var fadeClip:Sprite;
		
		/**
		 * currently executing action chain.
		 */
		private var curActionChain:ActionChain;
		
		/**
		 * Starting point for designer; used to put him back where he belongs after he moves around.
		 */
		private var designerStart:Point;
		
		/**
		 * In case we need to cancel a tween in progress, e.g. if scene is closed prematurely.
		 */
		private var curTween:TweenLite;
		
		private var achievements:AchievementGroup;
		
		public function CheeseInterior() {
			super();
		}
		
		// pre load setup
		override public function init( container:DisplayObjectContainer=null ):void {
			
			super.groupPrefix = "scenes/mocktropica/cheeseInterior/";
			super.init( container );
			
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void {
			super.load();
		} //
		
		// all assets ready
		override public function loaded():void {
			
			this.addSystem( new VariableTimelineSystem(), SystemPriorities.timelineControl );
			this.addSystem( new ValueMatchSystem(), SystemPriorities.update );
			this.addSystem( new WheelUpdateSystem(), SystemPriorities.update );
			this.addSystem( new WheelTargetSystem(), SystemPriorities.preUpdate );
			this.addSystem( new CheeseMachineSystem(), SystemPriorities.update );
			
			this.mockEvents = super.events as MocktropicaEvents;
			
			if ( this.shellApi.checkEvent( this.mockEvents.RESCUED_DESIGNER ) ) {
				
				// designer has been rescued. cheese machine must be broken. designer gone.
				this.removeMachineClips();
				this.initSmoke();
				this.initDrops();

				this.removeEntity( this.getEntityById( "designer" ) );
				this._hitContainer.removeChild( this.hitContainer["topConveyorDummy"] );	

				this.getEntityById( "topConveyer" ).remove( Mover );
				this.getEntityById( "bottomConveyer" ).remove( Mover );
				brokeMachine = true;

			} else {

				this.designer = this.getEntityById( "designer" );
				var spatial:Spatial = this.designer.get( Spatial );
				this.designerStart = new Point( spatial.x, spatial.y );
				
				// designer not rescued. scene intact.
				this.hideDestroyedMachine();
				
				this.initWheel();
				this.initIndicator();
				this.initMachine();

				/**
				 * set up the event that waits for the designer to talk, after which the curds zone
				 * will activate to get the player the curds.
				 */
				if ( !this.shellApi.checkItemEvent( "curds" ) ) {

					var dialog:Dialog = this.player.get( Dialog );
					dialog.start.add( this.testEnableCurdZone );
					
				}

			} // end-if.
			
			this.achievements = new AchievementGroup( this );
			this.addChildGroup( this.achievements );

			// Change: auto-check if achievement is completed.
			this.achievements.completeAchievement( mockEvents.ACHIEVEMENT_CHEESE_BALL );
			
			this.shellApi.eventTriggered.add( this.onEventTriggered );
			
			super.loaded();

		} //
		
		private function onEventTriggered( event:String, save:Boolean, init:Boolean=false, removeEvent:String=null ):void {
			
			if ( event == "freecurds" ) {
				
			} else if ( event == "axe_used" ) {
				
				this.useClimbingAxe();
				
			} else if ( event == "enableCurds" && !this.shellApi.checkItemEvent( "curds" ) ) {

				SceneUtil.lockInput( this, false );
				this.enableCheeseCurdZone();

			} //
			
		} //

		private function initWheel():void {
			
			var e:Entity = this.wheel = new Entity();
			var mc:MovieClip = this._hitContainer["wheel"];
			mc.gotoAndStop( 1 );
			
			var si:SceneInteraction = new SceneInteraction();
			si.reached.add( this.reachedWheel );
			
			e.add( new Id( "wheel" ) );			// need an id for Scene Interactions to work.
			e.add( new Display( mc ), Display );
			e.add( new Spatial( mc.x, mc.y ), Spatial );
			e.add( new Wheel(), Wheel );
			e.add( si, SceneInteraction );
			
			InteractionCreator.addToEntity( e, [ InteractionCreator.UP, InteractionCreator.DOWN, InteractionCreator.CLICK ] );
			
			this.addEntity( e );
			
			ToolTipCreator.addToEntity( e );
			
		} //
		
		/**
		 * The indicator has a ValueMatch component which matches the wheel angle with indicator position.
		 */
		private function initIndicator():void {
			
			var e:Entity = this.indicator = new Entity();
			var mc:MovieClip = this._hitContainer[ "indicator" ];
			
			var spatial:Spatial = new Spatial( mc.x, mc.y );
			
			var wheelObj:Wheel = this.wheel.get( Wheel ) as Wheel;
			/**
			 * This will match the rotation of the wheel with the position of the indicator.
			 */
			var valueMatch:ValueMatch = new ValueMatch( wheelObj, "angle", WHEEL_OFF_ANGLE, WHEEL_ON_ANGLE );
			valueMatch.addMatchVariable( spatial, "x", MACHINE_DIAL_MIN, MACHINE_DIAL_MAX );
			
			e.add( valueMatch, ValueMatch );
			
			e.add( new Display( mc ), Display );
			e.add( spatial, Spatial );
			
			this.addEntity( e );
			
		} //
		
		private function initMachine():void {
			
			var e:Entity = this.cheeseMachine = new Entity();
			var mc:MovieClip = this._hitContainer[ "assemblyLine" ];
			
			e.add( new Display( mc ), Display );
			e.add( new Spatial( mc.x, mc.y ), Spatial );
			
			// Need a special timeline to control the speed.
			var tl:VariableTimeline = new VariableTimeline();
			tl.loop = true;
			e.add( tl, VariableTimeline );
			tl.playing = true;
			
			var machine:CheeseMachine = new CheeseMachine( this.wheel, this.indicator );
			e.add( machine, CheeseMachine );
			
			// Match the cheese machine speed to the cheese timeline speed.
			// obviously could set the cheese timeline speed directly, but this handles accelerating in the machine itself.
			var valueMatch:ValueMatch = new ValueMatch( machine, "machineSpeed", MIN_MACHINE_SPEED, MAX_MACHINE_SPEED );
			valueMatch.addMatchVariable( tl, "rate", MIN_MACHINE_SPEED, MAX_MACHINE_SPEED );
			
			// get the two conveyer components. try to value match their speeds.
			var conveyer:Entity = this.getEntityById( "topConveyer" );
			var mover:Mover;
			if ( conveyer ) {
				mover = conveyer.get( Mover ) as Mover;
				if ( mover ) {
					valueMatch.addMatchVariable( mover.velocity, "x", 62, 390 );
				}
			}
			
			conveyer = this.getEntityById( "bottomConveyer" );
			if ( conveyer ) {
				mover = conveyer.get( Mover ) as Mover;
				if ( mover ) {
					valueMatch.addMatchVariable( mover.velocity, "x", -60, -390 );
				}
			}
			
			e.add( valueMatch, ValueMatch );
			
			this.addEntity( e );
			
			e = new Entity()
			mc = this._hitContainer[ "topConveyorDummy" ];	
			mc.visible = false;

			e.add( new Spatial( mc.x, mc.y ), Spatial );

			var proximity:Proximity = new Proximity(300, this.player.get(Spatial));
			proximity.entered.add(onPlayerNearTopConveyor);
			proximity.exited.add(onPlayerNotNearTopConveyor);
			e.add(proximity);
			addEntity (e)

			this.addSystem(new ProximitySystem());
				
		} //
		
		private function hideDestroyedMachine():void {
			
			this.destroyedMachineClip = this._hitContainer[ "destroyed" ];
			this._hitContainer.removeChild( this.destroyedMachineClip );

		} //

		/**
		 * Removes the machine clips for the working machine. This is for loading the scene after the machine has already
		 * been destroyed. A separate function is used to destroy the machine after it's already running - because
		 * the entities and components have to be removed separately.
		 */
		private function removeMachineClips():void {
			
			this._hitContainer.removeChild( this._hitContainer[ "indicator" ] );
			this._hitContainer.removeChild( this._hitContainer[ "wheel" ] );
			this._hitContainer.removeChild( this._hitContainer[ "assemblyLine" ] );

			this._hitContainer.removeChild( this._hitContainer[ "speedMachine" ] );

		} //

		/**
		 * When the machine breaks, because there is no animation for the actual breaking,
		 * perform a fade-out, fade-back-in and have the machine-break art revealed
		 * in between.
		 */
		private function doSceneFade( entity:Entity, machine:CheeseMachine ):void {
			
			// Might need to create a black screen here and tween that instead.

			this.fadeClip = ClipUtils.makeFadeClip( super.overlayContainer, 0, this.shellApi.viewportWidth, this.shellApi.viewportHeight );
			this.fadeClip.alpha = 0;
			
			this.curTween = TweenLite.to( this.fadeClip, 2.5, { alpha:1, onComplete:destroyMachine } );

		} //
		
		// Scene faded out while the machine was destroyed. Now take out the machine components and fade back into view.
		private function destroyMachine():void {

			// screen can stop shaking.
			this.player.remove( ScreenShake );

			this.wheel.remove( Wheel );
			this.indicator.remove( ValueMatch );
			this.cheeseMachine.remove( VariableTimeline );
			
			// swap broken and fixed machine clips.
			var machineClip:MovieClip = ( this.cheeseMachine.get( Display ) as Display ).displayObject as MovieClip;
			var index:int = this._hitContainer.getChildIndex( machineClip );
			this._hitContainer.removeChild( machineClip );
			this._hitContainer.addChildAt( this.destroyedMachineClip, index );

			this.removeEntity( this.cheeseMachine, true );
			this.removeEntity( this.indicator, true );

			this._hitContainer.removeChild( this._hitContainer[ "speedMachine" ] );

			this.getEntityById( "topConveyer" ).remove( Mover );
			this.getEntityById( "bottomConveyer" ).remove( Mover );

			this.initSmoke();
			this.initDrops();

			var wrap:AudioWrapper = AudioUtils.play( this, SoundManager.EFFECTS_PATH + "cheesey_doom.mp3" );
			wrap.complete.addOnce( this.doFadeIn );			// wait to fade in until audio is complete.

		} //

		/**
		 * Scene comes back into view after the fade-out has completed.
		 */
		private function machineDestroyed():void {
	
			this.overlayContainer.removeChild( this.fadeClip );
			this.fadeClip = null;
			
			var actChain:ActionChain = new ActionChain( this );
			actChain.lockInput = true;
			
			// Because this triggers more talk actions...
			actChain.addAction( new TalkAction( this.designer, "machineBroke1" ) );
			actChain.addAction( new TalkAction( this.player, "machineBroke2" ) );
			actChain.addAction( new TalkAction( this.designer, "machineBroke3" ) );
			actChain.addAction( new RemoveItemAction( "designer_id", "designer" ) );
			
			actChain.execute( this.destroyedSequenceDone );
			
		} //
		
		/**
		 * Complete destruction sequence is complete - including the talk sequence that occurs after the destroyed
		 * machine becomes visible.
		 */
		private function destroyedSequenceDone( chain:ActionChain ):void {
			
			this.achievements.completeAchievement( this.mockEvents.ACHIEVEMENT_CURD_BURGLAR, onAchievementComplete );
			this.shellApi.completeEvent( this.mockEvents.RESCUED_DESIGNER );
			
		} //
		
		// Go back to the poptropica base.
		private function loadBasement():void {
			
			this.shellApi.loadScene( Basement );
			
		} //

		private function onAchievementComplete():void
		{
			shellApi.takePhotoByEvent( mockEvents.RESCUED_DESIGNER, loadBasement );
		}

		private function testEnableCurdZone( data:DialogData ):void {

			if ( data.id == "nullquestion2" && !this.shellApi.checkItemEvent( "curds" ) ) {

				SceneUtil.lockInput( this, true );

				var dialog:Dialog = this.player.get( Dialog ) as Dialog;
				dialog.start.remove( this.testEnableCurdZone );

			} //

		} //

		private function reachedWheel( char:Entity, wheel:Entity ):void {
			
			/**
			 * Machine already broken.
			 */
			if ( this.brokeMachine == true ) {
				return;
			}
			
			var wheelTarget:WheelTarget = this.wheel.get( WheelTarget );
			if ( !wheelTarget ) {
				wheelTarget = new WheelTarget();
				this.wheel.add( wheelTarget, WheelTarget );
			}
			var wheelInfo:Wheel = this.wheel.get( Wheel );
			
			var actChain:ActionChain = new ActionChain( this );
			actChain.autoUnlock = true;
			actChain.lockInput = true;
			
			var act:ActionCommand = new AnimationAction( player, Throw );
			act.noWait = true;
			
			actChain.addAction( act );
			actChain.addAction( new CallFunctionAction( Command.create(wheelTarget.setTargetAngle,WHEEL_ON_ANGLE) ) );
			actChain.addAction(
				new CallFunctionAction(  Command.create((this.cheeseMachine.get( CheeseMachine ) as CheeseMachine ).setTargetSpeed, this.MEDIUM_MACHINE_SPEED) ) );
			
			// We could actually just listen for the signal here, but better to do it all in an action chain,
			// for both clarity and for making sure the whole sequence can be cleared, cancelled.
			actChain.addAction( new WaitSignalAction( wheelTarget.onTargetDone ) );
			
			actChain.execute( this.playerTurnedWheel );
			
		} //
		
		private function playerTurnedWheel( actChain:ActionChain ):void {
			
			// if the wheel has been broken since the action began, it can now spiral out of control
			// if not, the designer comes and turns the wheel off.
			if ( this.brokeMachine != true ) {
				
				this.designerTurnOffWheel();
				
			} //
			
		} //
		
		/**
		 * Once the wheel is turned, I guess the designer has to come back and turn it off.
		 */
		private function onWheelTurnedOn( wheel:Entity ):void {
			
			var actChain:ActionChain = new ActionChain( this );
			actChain.autoUnlock = true;
			actChain.lockInput = true;
			
			actChain.addAction( new MoveAction( this.designer, this.wheel, null, (wheel.get(Spatial) as Spatial).x ) );
			// put in some character animation that looks like wheel turning.
			
			this.curActionChain = actChain;
			actChain.execute( this.designerTurnOffWheel );
			
		} //
		
		/**
		 * The player set the machine to high. Now the designer walks over and turns it off like a jerk.
		 */
		private function designerTurnOffWheel():void {
			
			if ( this.brokeMachine == true ) {
				return;
			}
			
			var actChain:ActionChain = new ActionChain( this );
			
			actChain.addAction( new MoveAction( this.designer, this.wheel ) );
			actChain.addAction( new TalkAction( this.designer, "dont_touch" ) );
			actChain.addAction( new AnimationAction( this.designer, Throw ) );
			
			var wheelTarget:WheelTarget = this.wheel.get( WheelTarget ) as WheelTarget;
			
			actChain.addAction( new CallFunctionAction( Command.create(wheelTarget.setTargetAngle, WHEEL_OFF_ANGLE) ) );
			actChain.addAction(
				new CallFunctionAction( Command.create((this.cheeseMachine.get( CheeseMachine ) as CheeseMachine ).setTargetSpeed, 1) ) );
			
			actChain.addAction( new WaitSignalAction( wheelTarget.onTargetDone ) );
			
			// Move designer back to his original position.
			var act:MoveAction = new MoveAction( this.designer, this.designerStart );
			act.noWait = true;
			actChain.addAction( act );
			
			actChain.execute( this.onWheelTurnedOff );
			
		} //

		/**
		 * The designer turned the wheel back to normal after the player turned it on high speed.
		 */
		private function onWheelTurnedOff( actChain:ActionChain ):void {
			
			//trace( "WHEEL TURNED OFF" );
			
		} //
		
		/**
		 * Try to destroy the crank and make the cheese machine spiral out of control.
		 */
		private function useClimbingAxe():void {
			
			if ( this.brokeMachine == true ) {
				( player.get( Dialog ) as Dialog ).sayById( "no_use_axe" );
				return;
			}
			
			// First test distance to the wheel that you need to break.
			var wheelSpatial:Spatial = this.wheel.get( Spatial ) as Spatial;
			var pSpatial:Spatial = this.player.get( Spatial ) as Spatial;
			
			var dx:Number = wheelSpatial.x - pSpatial.x;
			var dy:Number = pSpatial.y - wheelSpatial.y;
			if ( Math.abs( dx ) > 400 || dy > 150 ) {
				
				// too far away. say can't use that here.
				( player.get( Dialog ) as Dialog ).sayById( "no_use_axe" );
				return;
				
			} //
			
			// move player to the wheel, perform some sort of animation with the axe in hand, break wheel.
			var actionChain:ActionChain = new ActionChain( this );
			actionChain.lockInput = true;
			actionChain.autoUnlock = false;
			
			actionChain.addAction( new SetSkinAction( this.player, SkinUtils.ITEM, "mk_axec", false, true ) );
			actionChain.addAction( new MoveAction( this.player, wheelSpatial, new Point( 100, 80 ), wheelSpatial.x ) );
			actionChain.addAction( new MoveAction( this.designer, new Point( 1530, 461 ), null, wheelSpatial.x ) );
			actionChain.addAction( new AnimationAction( this.player, Attack ) );
			
			actionChain.execute( this.useAxeDone );

			var tl:Timeline = this.player.get( Timeline ) as Timeline;
			tl.handleLabel( "trigger", this.breakWheel, true );

		} //

		private function breakWheel():void {

			AudioUtils.play( this, SoundManager.EFFECTS_PATH + "metal_impact_07.mp3" );

			// Show wheel as broken.
			var wheelClip:MovieClip = ( this.wheel.get( Display ) as Display ).displayObject as MovieClip;
			wheelClip.gotoAndStop( 2 );

		} //

		/**
		 * Break the machine wheel. start the scene shaking - slow ramp up?
		 */
		private function useAxeDone( chain:ActionChain ):void {

			SkinUtils.getSkinPart(this.player, SkinUtils.ITEM).revertValue();

			this.brokeMachine = true;
			
			// Designer gets mad.
			CharUtils.setAnim( this.designer, Grief, false );
			
			// Turn machine to crazy speed.
			var machine:CheeseMachine = this.cheeseMachine.get( CheeseMachine ) as CheeseMachine;
			machine.setTargetSpeed( this.MAX_MACHINE_SPEED );
			machine.breakMachine( 5 );
			machine.onMachineBroken.addOnce( this.doSceneFade );
			
			// Move wheel to 'on' position/
			var target:WheelTarget = this.wheel.get( WheelTarget );
			if ( target == null ) {
				target = new WheelTarget();
				this.wheel.add( target, WheelTarget );
			}
			target.setTargetAngle( WHEEL_ON_ANGLE );

			// start the scene shaking.
			this.addSystem( new ScreenShakeSystem(), SystemPriorities.update );
			var shake:ScreenShake = new ScreenShake( 10 );

			this.player.add( shake, ScreenShake );

		} // End function useAxeDone()

		/**
		 * When the player turns the leave, this zone is activated so the player
		 * is given the cheese curds when they touch it.
		 */
		private function enableCheeseCurdZone():void {
			
			var e:Entity = this.getEntityById( "cheeseCurdZone" );
			
			var zone:Zone = e.get( Zone );
			zone.entered.add( this.enteredCheeseCurdZone );
			
		} //
		
		/**
		 * The player entered the zone where the designer turns and gives them the cheese curds.
		 * Get the cheese curds; earn an achievement.
		 */
		private function enteredCheeseCurdZone( zone:String, char:String ):void {
			
			if ( char != "player" ) {
				return;
			}
			
			var chain:ActionChain = new ActionChain( this );
			chain.lockInput = true;
			
			chain.addAction( new PanAction( designer ) );
			chain.addAction( new TalkAction( designer, "freecurds" ) );
			chain.addAction( new GetItemAction( "curds" ) );
			
			chain.execute( gotCurds );
			
		} //

		/**
		 * Called after the designer has given the player the stupid cheese curds.
		 */
		private function gotCurds( chain:ActionChain ):void {
			
			/**
			 * No longer need the cheeseCurdZone that checks when to give the player
			 * the stupid cheese curds.
			 */
			this.removeEntity( this.getEntityById( "cheeseCurdZone" ) );
			
			SceneUtil.setCameraTarget( this, this.player );
			
			this.achievements.completeAchievement( this.mockEvents.ACHIEVEMENT_MIC_SQUEAK );
			
		} //
		
		private function onPlayerNearTopConveyor (e:Entity):void {
			trace ("[CheeseInterior] onPlayerNearTopConveyor")
			var a:AudioWrapper = AudioUtils.play(this, SoundManager.EFFECTS_PATH + "conveyor_belt_01_L.mp3",1,true);
			//a.fadeTarget
			//AudioUtils.createSoundEntity(
			
		}
		
		private function onPlayerNotNearTopConveyor (e:Entity):void {
			trace ("[CheeseInterior] onPlayerNotNearTopConveyor")
		//	AudioUtils.play(this, SoundManager.MUSIC_PATH + "MiniGameWin.mp3");
		}

		private function doFadeIn():void {

			// tween the scene back into view.
			this.curTween = TweenLite.to( this.fadeClip, 2.5, { alpha:0, onComplete:machineDestroyed } );

		} //

		/**
		 * Just ugh.
		 */
		private function initDrops():void {

			var emitter:DropletEmitter;
			var dropper:Entity;

			var i:int = 1;
			var clip:MovieClip = this._hitContainer["dropper"+i];

			while ( clip ) {

				if ( i != 1 ) {
					emitter = new DropletEmitter( clip.x, clip.y, 0xFEFE60, 3, 138 );
				} else {
					emitter = new DropletEmitter( clip.x, clip.y, 0xFEFE60, 3, 214 );
				} //

				dropper = EmitterCreator.create( this, super._hitContainer, emitter );

				emitter.init();

				this._hitContainer.removeChild( clip );			// don't need it anymore.

				i++;
				clip = this._hitContainer["dropper"+i];

			} // while.

		} // initDrops()

		private function initSmoke():void {

			var sys:SmokeWispSystem = new SmokeWispSystem();
			this.addSystem( sys, SystemPriorities.update );

			var i:int = 1;
			var mc:MovieClip = this._hitContainer["smoke"+i];
			
			var e:Entity;
			var w:SmokeWisp;
			
			while ( mc ) {

				w = new SmokeWisp();
				w.shiftRange = 20;
				w.drawPoints = new Vector.<smokePoint>();
				w.lineMc = mc;

				e = EntityUtils.createSpatialEntity( this, w.lineMc );
				e.add( w, SmokeWisp );

				i++;
				mc = this._hitContainer["smoke"+i];

			} //
			
		} //

		/*private function initSmoke():void {

			var i:int = 1;
			var mc:MovieClip = this._hitContainer["smoke"+i];

			var e:Entity;
			var w:SmokeWisp;

			while ( mc ) {

				w = new SmokeWisp();
				w.shiftRange = 20;
				w.drawPoints = new Vector.<smokePoint>();
				w.lineMc = mc;

				e = EntityUtils.createSpatialEntity( this, w.lineMc );
				e.add( w, SmokeWisp );

				i++;
				mc = this._hitContainer["smoke"+i];

			} //

			this.addSystem( new SmokeWispSystem(), SystemPriorities.preRender );

		} //*/
		
		override public function destroy():void {

			if ( this.curTween != null ) {
				this.curTween.kill();
				this.curTween = null;
			}

			super.destroy();

		} //
		
	} // end class
	
} //