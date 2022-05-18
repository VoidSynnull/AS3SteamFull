package game.scenes.myth.mountOlympus3.bossStates
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Spatial;
	import engine.group.Scene;
	
	import game.components.motion.Destination;
	import game.components.motion.MotionTarget;
	import game.util.MotionUtils;
	import game.util.Utils;
	
	public class MoveState extends ZeusState
	{
		public var goal:Spatial;
		public var target:MotionTarget;
		private var _sceneBounds:Rectangle;
		private const BOUNDS_BUFFER:int = 60;
		private var _xMax:int = 0;
		private var _yMax:int = 0;
		
		public function MoveState()
		{
			type = "move";
		}
		
		override public function exit():void
		{
			node.motion.zeroMotion();
			node.motionControl.moveToTarget = false;
			node.motionControl.forceTarget = false;
		}
		
		override public function start():void
		{
			super.start();
			// zero motion
			//node.motion.zeroMotion();
			
			var goalX:Number = 0;
			var goalY:Number = 0;
			
			// setup bounds
			if( _sceneBounds == null )	{ _sceneBounds = (node.owningGroup.group as Scene).sceneData.bounds; }
			if( _xMax == 0 )	{ _xMax = _sceneBounds.width - BOUNDS_BUFFER; }
			if( _yMax == 0 )	{ _yMax  = _sceneBounds.height - BOUNDS_BUFFER; }

			// determine random position
			do { goalX = Utils.randInRange( BOUNDS_BUFFER, _xMax ); }
			while( Math.abs( goalX - node.spatial.x ) < 200 );
			
			do { goalY = Utils.randInRange( BOUNDS_BUFFER, _yMax ); }
			while( Math.abs( goalY - node.spatial.y ) < 200 );
			
			// set position
			var destination:Destination = MotionUtils.moveToTarget( node.entity, goalX, goalY, true, pickNextState, new Point( 200, 200 ) );
			destination.motionToZero.push( "x" );
			destination.motionToZero.push( "y" );
			
			// set acceleration
			node.motionControlBase.acceleration = 600;
			//node.motionControlBase.maxVelocityByTargetDistance = 200;
		}
		
		private function pickNextState( entity:Entity = null ):void
		{
			if( node.fsmControl.state.type != ZeusState.DEFEAT )
			{
				var nextState:String = node.boss.getNextState();
				node.fsmControl.setState( nextState );
			}
		}		
	}
}