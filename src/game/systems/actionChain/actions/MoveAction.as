package game.systems.actionChain.actions {

	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.group.Group;
	
	import game.components.motion.Destination;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.systems.actionChain.ActionCommand;
	import game.util.CharUtils;

	public class MoveAction extends ActionCommand 
	{
		public var target:*;
		public var directionX:Number;
		public var minDist:Point;
		private var callback:Function;
		public var restoreControl:Boolean = true;
		public var ignorePlatformTarget:Boolean = false;
		public var waitForCompletion:Boolean = true;

		// Target may be:
		// an Entity with a display or spatial component
		// any object with x,y variables: Spatial, DisplayObject, Point
		// a Display component.
		public function MoveAction( char:Entity, target:*, minDist:Point=null, directionTargetX:Number=NaN, ignorePlatformTarget:Boolean = false ) 
		{
			this.entity = char;
			this.target = target;
			this.minDist = minDist;
			this.directionX = directionTargetX;
			this.ignorePlatformTarget = ignorePlatformTarget;
		}

		override public function preExecute( callback:Function, group:Group, node:SpecialAbilityNode = null ):void {

			this.callback = callback;

			if ( this.target is Entity ) 
			{
				var spatial:Spatial = this.target.get( Spatial );
				if ( spatial == null )
				{
					var display:Display = this.target.get( Display );
					if ( display == null ) {
						// ERROR: no damned x,y on this entity.
						callback();
						return;
					} else {
						beginMove(display.displayObject.x, display.displayObject.y);
						//CharUtils.moveToTarget( entity, display.displayObject.x, display.displayObject.y, true, moveDone, minDist  ).setDirectionOnReached("", directionX );
					}
				}
				else 
				{
					beginMove(spatial.x,spatial.y);
					//CharUtils.moveToTarget( entity, spatial.x, spatial.y, true, moveDone, minDist ).setDirectionOnReached("", directionX );
				} 
			} 
			else if ( target is Point || (target.hasOwnProperty("x") && target.hasOwnProperty("y"))) 
			{
				beginMove(target.x,target.y);
				//CharUtils.moveToTarget( entity, target.x, target.y, true, moveDone, minDist ).setDirectionOnReached("", directionX );
			} 
			else if ( target is Display ) 
			{
				var d:DisplayObjectContainer = (target as Display).displayObject;
				beginMove(d.x,d.y);
				//CharUtils.moveToTarget( entity, d.x, d.y, true, moveDone, minDist ).setDirectionOnReached("", directionX );
			} 
			else if (target is Vector.<Point>)
			{
				CharUtils.followPath(entity, target, moveDone, true, false, minDist, ignorePlatformTarget).setDirectionOnReached("", directionX);
			}
			else 
			{
				// UNEXPECTED TARGET.
				group.shellApi.log( "Error: Unexpected move target: " + target );
				callback();
			}
		}
		
		public function beginMove( x:Number, y:Number ):void 
		{
			var dest:Destination = CharUtils.moveToTarget( entity, x, y, true, moveDone, minDist);
			dest.setDirectionOnReached("", directionX );
			dest.ignorePlatformTarget = this.ignorePlatformTarget;
		}

		public function moveDone( character:Entity ):void 
		{
			if ( restoreControl ) 
			{
				//( character.get(MotionControl) as MotionControl ).lockInput = false;
			}
			callback();
		} 
	}
}