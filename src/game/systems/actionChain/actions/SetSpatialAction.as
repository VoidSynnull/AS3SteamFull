package game.systems.actionChain.actions
{
	import ash.core.Entity;
	
	import engine.components.Spatial;
	import engine.group.Group;
	
	import game.systems.actionChain.ActionCommand;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import flash.geom.Point;

	// Set spatial property of an object or entity
	public class SetSpatialAction extends ActionCommand
	{
		public var object:*;
		public var point:Point;

		/**
		 * Set spatial property of an object or entity
		 * @param object		Object - can be entity
		 * @param point			Spatial point
		 */
		public function SetSpatialAction( object:*, point:Point ) 
		{
			this.object 		= object;
			this.point 			= point;
		}

		override public function preExecute( callback:Function, group:Group, node:SpecialAbilityNode = null ):void 
		{
			// if object valid
			if ( object )
			{
				// if entity
				if (object is Entity)
				{
					Entity(object).get(Spatial).x = point.x;
					Entity(object).get(Spatial).y = point.y;
				}
				else
				{
					// if not entity
					object.x = point.x;
					object.y = point.y;
				}
			}
			callback();	// once the waitStart timer has completed, execute() is called, and we finish right away.
		}
	}
}