package game.scenes.ghd.lostTriangle
{
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.Tween;
	
	import game.components.Emitter;
	import game.components.animation.FSMControl;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.CharacterMovement;
	import game.components.input.Input;
	import game.components.motion.Edge;
	import game.creators.animation.FSMStateCreator;
	import game.creators.entity.EmitterCreator;
	import game.data.display.BitmapWrapper;
	import game.scene.template.CharacterGroup;
	import game.scenes.ghd.GalacticHotDogEvents;
	import game.scenes.ghd.ghostShip.GhostShip;
	import game.scenes.ghd.lostTriangle.components.JetpackHealth;
	import game.scenes.ghd.lostTriangle.nodes.JetPackStateNode;
	import game.scenes.ghd.lostTriangle.states.JetPackHover;
	import game.scenes.ghd.lostTriangle.states.JetPackHurt;
	import game.scenes.ghd.lostTriangle.states.JetPackPropel;
	import game.scenes.ghd.lostTriangle.states.JetPackState;
	import game.scenes.ghd.neonWiener.NeonWiener;
	import game.scenes.shrink.carGame.creators.RaceSegmentCreator;
	import game.scenes.survival5.chase.scenes.EndlessRunnerScene;
	import game.systems.SystemPriorities;
	import game.systems.entity.character.DialogInteractionSystem;
	import game.systems.hit.BaseGroundHitSystem;
	import game.systems.motion.MotionControlBaseSystem;
	import game.systems.motion.NavigationSystem;
	import game.ui.elements.DualTextDialogPicturePopup;
	import game.util.BitmapUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.utils.LoopingSceneUtils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.ZeroCounter;
	import org.flintparticles.common.displayObjects.Ring;
	import org.flintparticles.common.initializers.BitmapImage;
	import org.flintparticles.common.initializers.ColorInit;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.AccelerateToPoint;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.zones.PointZone;
	
	public class LostTriangle extends EndlessRunnerScene
	{
		private const SPACE_SUIT:String				=   "ghd_spacesuit";
		private const FAILED_LOST_TRIANGLE:String	=	"failed_lost_triangle";
		private var _events:GalacticHotDogEvents;
		
		public function LostTriangle()
		{
			super();
		}
		
		override public function init( container:DisplayObjectContainer = null ):void
		{			
			super.groupPrefix = "scenes/ghd/lostTriangle/";
			
			_events = new GalacticHotDogEvents();
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		override protected function addBaseSystems():void
		{
			super.addBaseSystems();
			super.removeSystemByClass( BaseGroundHitSystem );
			addSystem( new MotionControlBaseSystem(), SystemPriorities.move );
		}
		
		override protected function addCharacters():void
		{
			var charContainer:DisplayObjectContainer = ( _hitContainer ) ? _hitContainer : super.groupContainer;
			
			// this group handles loading characters, npcs (parses npcs.xml), and creates the player character.
			var characterGroup:CharacterGroup = new CharacterGroup();
			characterGroup.setupScene( this, charContainer, super.getData("npcs.xml"), addLoopers, (super.sceneData.startPosition!=null));
			
			super.addSystem(new DialogInteractionSystem(), SystemPriorities.lowest);
			super.addSystem(new NavigationSystem(), SystemPriorities.update);
		}
		
	 	protected function addLoopers():void
		{
			var raceObstacleCreator:RaceSegmentCreator = new RaceSegmentCreator();
			var data:XML = SceneUtil.mergeSharedData( this, "segmentPatterns.xml", "ignore" );
			
			raceObstacleCreator.createSegments( this, data, _hitContainer, _audioGroup, allCharactersLoaded );
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			this.shellApi.setUserField(_events.PLANET_FIELD, _events.LOST_TRIANGLE, this.shellApi.island, true);
			
			optimizeAssets();
			shellApi.eventTriggered.add( eventTriggers );
			
			setupPlayer();
			LoopingSceneUtils.createMotion(this, cameraStationary, finishedRace);
			super.triggerLayers();
			super.triggerObstacles();
			
			var characterMotion:CharacterMotionControl = player.get( CharacterMotionControl );
			var motion:Motion = player.get( Motion );
			motion.maxVelocity.y = motion.velocity.y = motion.previousAcceleration.y = motion.acceleration.y = motion.lastVelocity.y = characterMotion.gravity = 
			motion.maxVelocity.x = motion.velocity.x = motion.previousAcceleration.x = motion.acceleration.x = motion.lastVelocity.x = 0;		
			
			// position miasma
			var spatial:Spatial;
			for( var number:int = 1; number < 3; number ++ )
			{
				spatial 						=	getEntityById( "topMiasma" + number ).get( Spatial );
				spatial.y 						=	( shellApi.viewportHeight + spatial.height ) * -.5 * shellApi.viewportScale;
				
				spatial 						=	getEntityById( "bottomMiasma" + number ).get( Spatial );
				spatial.y 						=	( shellApi.viewportHeight - spatial.height ) * .5 * shellApi.viewportScale;
			}
		}
		
		override protected function setupPlayer( fileName:String="motionMaster.xml" ):void
		{
			super.setupPlayer(fileName);
			
			CharacterMovement( player.get( CharacterMovement )).active = false;   
			
			// add spacesuit
			var skinParts:Array = [ SkinUtils.MOUTH
										, SkinUtils.FACIAL
										, SkinUtils.HAIR
										, SkinUtils.SHIRT
										, SkinUtils.PACK
										, SkinUtils.OVERSHIRT ];
			var values:Array = [ "5", SPACE_SUIT, "1", "1", SPACE_SUIT, SPACE_SUIT ];
			
			for( var number:int = 0; number < values.length; number ++ )
			{
				SkinUtils.setSkinPart( player, skinParts[ number ], values[ number ], false, null, true );
			}
			
			player.add( new JetpackHealth());
			var spatial:Spatial = player.get( Spatial );
			
			// ADD EXHAUST TO JETPACK
			var bitmapData:BitmapData = BitmapUtils.createBitmapData( new Ring( 5, 7 ));
			var emitter2D:Emitter2D;
			
			emitter2D = new Emitter2D();
			emitter2D.counter = new ZeroCounter();
			emitter2D.addInitializer( new BitmapImage( bitmapData, true, 35 ));
			emitter2D.addInitializer( new Position( new PointZone( new Point( -20, 0 ))));
			emitter2D.addInitializer( new Lifetime( .5 ));
			emitter2D.addInitializer( new ColorInit( 0xEEEEEE, 0xFFFFFF ));
			
			emitter2D.addAction( new Fade( 1, .25 ));		
			emitter2D.addAction( new ScaleImage( .4, 1.5 ));
			emitter2D.addAction( new AccelerateToPoint( 500, -500, 750 ));						
			emitter2D.addAction( new Age());
			emitter2D.addAction( new Move());
			var exhaust:Entity = EmitterCreator.create( this, _hitContainer, emitter2D, 0, 0, null, "exhaustEmitter", spatial, false );
			var display:Display = exhaust.get( Display );
			display.moveToBack();
			
			// SETUP FSM
			var fsmControl:FSMControl = player.get( FSMControl );
			fsmControl.removeAll(); 
			
			var stateCreator:FSMStateCreator = new FSMStateCreator();
			var stateClasses:Vector.<Class> = new <Class>[ JetPackHover, JetPackHurt, JetPackPropel ];
			
			stateCreator.createStateSet( stateClasses, player, JetPackStateNode );
			fsmControl.setState( JetPackState.HOVER );
			
			var hoverState:JetPackHover = fsmControl.getState( JetPackState.HOVER ) as JetPackHover;
			SceneUtil.getInput( this ).inputDown.add( hoverState.onActiveInput );
			SceneUtil.getInput( this ).inputUp.add( hoverState.onInactiveInput );
			var input:Input  = shellApi.inputEntity.get( Input );
			
			var type:String;
			for each( type in JetPackState.STATES )
			{
				var fsmState:JetPackState = fsmControl.getState( type ) as JetPackState;
				fsmState.init( input, exhaust.get( Emitter ));
			}
			
			spatial.x = 100;
			spatial.y = 325;
		}
		
		private function optimizeAssets():void
		{
			var clip:DisplayObject = _hitContainer[ "ghostShip" ];
			var wrapper:BitmapWrapper = DisplayUtils.convertToBitmapSprite( clip );
			
			var entity:Entity = EntityUtils.createSpatialEntity( this, wrapper.sprite );
			entity.add( new Id( "ghostShip" ));
		}
		
		/**
		 * EVENT HANDLING
		 */
		protected function eventTriggers( event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			if( event == FAILED_LOST_TRIANGLE )
			{
				var losePopup:DualTextDialogPicturePopup = new DualTextDialogPicturePopup( overlayContainer, false, true );
				losePopup.updateText( "You got caught in the debris field.", null, "try again", "give up" );
				losePopup.configData( "losePopup.swf", "scenes/ghd/lostTriangle/" );
				losePopup.buttonClicked.addOnce( restartChoice );
				addChildGroup( losePopup );
			}
		}
		
		private function restartChoice( restart:Boolean ):void
		{
			if( restart )
			{
				shellApi.loadScene( LostTriangle );
			}
			else
			{
				shellApi.loadScene( NeonWiener );
			}
		}
		
		override protected function finishedRace( ...args ):void
		{
			SceneUtil.lockInput( this );
			var ghostShip:Entity = getEntityById( "ghostShip" );
			var spatial:Spatial = ghostShip.get( Spatial );
			
			var characterMotion:CharacterMotionControl = player.get( CharacterMotionControl );
			var motion:Motion = player.get( Motion );
			motion.maxVelocity.y = motion.velocity.y = motion.previousAcceleration.y = motion.acceleration.y = motion.lastVelocity.y = characterMotion.gravity = 0;
			
			var tween:Tween = new Tween();
			tween.to( spatial, 5, { x : 820, onComplete : enterGhostShip });
			ghostShip.add( tween );
			
			var jetpackHealth:JetpackHealth = player.get( JetpackHealth );
			jetpackHealth.complete = true;
		}
		
		/**
		 * YOU WIN
		 */
		private function enterGhostShip( ...args ):void
		{
			// TODO :: add animation for this entrance
			shellApi.loadScene( GhostShip );
		}
	}
}