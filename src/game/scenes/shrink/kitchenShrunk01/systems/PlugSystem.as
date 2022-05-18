package game.scenes.shrink.kitchenShrunk01.systems
{
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.util.Command;
	
	import game.components.entity.character.animation.RigAnimation;
	import game.components.hit.CurrentHit;
	import game.data.motion.time.FixedTimestep;
	import game.scenes.shrink.kitchenShrunk01.nodes.PlugNode;
	import game.scenes.shrink.shared.groups.CarryGroup;
	import game.systems.GameSystem;
	import game.util.DisplayUtils;
	
	public class PlugSystem extends GameSystem
	{
		public function PlugSystem(carryGroup:CarryGroup)
		{
			_carryGroup = carryGroup;
			super(PlugNode, updateNode, addNode);
			this.fixedTimestep = FixedTimestep.MOTION_TIME;
			this.linkedUpdate = FixedTimestep.MOTION_LINK;
		}
		
		public function addNode(node:PlugNode):void
		{
			node.sceneInteraction.reached.add(Command.create(plugClicked, node));
			
			node.plug.holdingPlug = false;
			_isStill = true;
		}
		
		public function updateNode(node:PlugNode, time:Number):void
		{
			var cord:MovieClip = node.plug.cord;
			var plug:Entity = node.entity;
			var plugSpatial:Spatial = node.spatial;
			var followSpatial:Spatial = node.plug.follow.get(Spatial);
			var socket:Entity = node.plug.socket;
			var offset:Point = new Point();
			var rigAnim:RigAnimation;
			
			// if holding plug
			if( node.plug.holdingPlug )
			{
				if( !node.plug.goodZone.contains( followSpatial.x, followSpatial.y ))
				{
					node.plug.holdingPlug = false;
					_isStill = false;
					_drawCord = true;
					DisplayUtils.moveToOverUnder( node.plug.follow.get(Display).displayObject, node.display.displayObject, true );
					DisplayUtils.moveToOverUnder( node.plug.follow.get(Display).displayObject, cord, true );
				}
				else
				{
					offset = new Point( followSpatial.x - ( 55 * followSpatial.scaleX ), followSpatial.y - ( 125 * followSpatial.scaleY ));
				}
				// Move the line to the middle of the plug
			}
			
			// dropped plug
			if( !node.plug.holdingPlug && !_isStill ) 
			{
				_carryGroup.dropItem(node.entity, node.plug.follow);
				var currentHit:CurrentHit = node.currentHit;
				
				if(currentHit != null && currentHit.hit != null)
				{
					node.motion.velocity.x = 0;
					node.motion.velocity.y = 0;
					_isStill = true;
					_drawCord = true;
					DisplayUtils.moveToOverUnder( node.plug.follow.get(Display).displayObject, node.display.displayObject, false );
					DisplayUtils.moveToOverUnder( cord, node.display.displayObject, true );
				}
				else
				{
					if(followSpatial.x > node.plug.goodZone.right)
					{
						node.motion.velocity.x = node.plug.goodZone.right - followSpatial.x;
					}
					else
					{
						node.motion.velocity.x = node.plug.goodZone.left - followSpatial.x;
					}
					
					node.motion.velocity.y = 200;
				}
			}
			
			cord.graphics.clear();
			cord.graphics.lineStyle( 10, 0x393A33, 1 );
			cord.graphics.curveTo(( plugSpatial.x + offset.x - cord.x ) / 2, 20, plugSpatial.x + offset.x - cord.x, plugSpatial.y + offset.y - cord.y );
		}
		
		private function plugClicked(char:Entity, plug:Entity, node:PlugNode):void
		{	
			node.plug.holdingPlug = !node.plug.holdingPlug;
			
			if( node.plug.holdingPlug )
			{
				DisplayUtils.moveToOverUnder( node.plug.follow.get(Display).displayObject, node.display.displayObject, false );
				DisplayUtils.moveToOverUnder( node.plug.cord, node.plug.follow.get(Display).displayObject, true );
			}
			else
			{
				DisplayUtils.moveToOverUnder( node.plug.follow.get( Display ).displayObject, node.display.displayObject, true );
				DisplayUtils.moveToOverUnder( node.plug.cord, node.plug.follow.get(Display).displayObject, true );
			}
			
			_isStill = false;
		}
		
		private var _isStill:Boolean;
		private var _drawCord:Boolean = true;
		private var _carryGroup:CarryGroup;
	}
}