package game.scenes.shrink.carGame
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import engine.components.Display;
	
	import game.components.animation.FSMControl;
	import game.components.animation.FSMMaster;
	import game.components.input.Input;
	import game.components.motion.MotionControl;
	import game.creators.animation.FSMStateCreator;
	import game.scenes.shrink.carGame.nodes.TopDownCollisionNode;
	import game.scenes.shrink.carGame.scenes.TopDownRaceScene;
	import game.scenes.shrink.carGame.states.TopDownDrive;
	import game.scenes.shrink.carGame.states.TopDownDriverState;
	import game.scenes.shrink.carGame.states.TopDownFall;
	import game.scenes.shrink.carGame.states.TopDownInCulvert;
	import game.scenes.shrink.carGame.states.TopDownJump;
	import game.scenes.shrink.carGame.states.TopDownSpin;
	import game.scenes.shrink.shared.popups.Ramp;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	import game.utils.LoopingSceneUtils;
	
	public class CarGame extends TopDownRaceScene
	{
		public function CarGame()
		{
			super();
		}
		
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/shrink/carGame/";
			super.vehicleURL = "scenes/shrink/carGame/jeep.swf";
			
			super.init(container);
		}
		
		override public function load():void
		{
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			var clip:MovieClip = Display( shellApi.player.get( Display )).displayObject;
			
			TimelineUtils.convertClip( clip.vehicle, this, shellApi.player, null, false );

			setupPlayer();
			LoopingSceneUtils.createMotion(this, cameraStationary, finishedRace);
			addStates();
			triggerLayers();
			triggerObstacles();
		}
		
		override protected function addStates():void
		{
			var fsmState:TopDownDriverState;
			var input:Input;
			var type:String;
			var fsmControl:FSMControl = new FSMControl(super.shellApi);
			player.add( fsmControl ).add( new FSMMaster());
			
			var stateCreator:FSMStateCreator = new FSMStateCreator();
			var stateClasses:Vector.<Class> = new <Class>[ TopDownJump, TopDownDrive, TopDownInCulvert, TopDownFall, TopDownSpin ];// TopDownDriverState ];
			stateCreator.createStateSet( stateClasses, player, TopDownCollisionNode );
			
			fsmControl.setState( TopDownDriverState.DRIVE );
			
			for each( type in TopDownDriverState.STATES )
			{
				input = null;
				fsmState = fsmControl.getState( type ) as TopDownDriverState;
				
				if( type == TopDownDriverState.DRIVE )
				{
					input = shellApi.inputEntity.get( Input );
				}
				fsmState.init( input );
			}		
			
			MotionControl( player.get( MotionControl )).moveToTarget = true;
		}
		
		override protected function finishedRace( ...args ):void
		{
			shellApi.completeEvent( "won_car_game" );
			SceneUtil.lockInput( this );
			addChildGroup( new Ramp( super.overlayContainer )) as Ramp;
		}
	}
}