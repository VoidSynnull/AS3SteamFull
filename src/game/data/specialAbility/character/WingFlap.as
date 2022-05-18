// Used by:
// Cards 3063 and 3064 using pack pangelwings

package game.data.specialAbility.character
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.util.CharUtils;
	
	/**
	 * Flap wings in pack part 
	 */
	public class WingFlap extends SpecialAbility
	{
		override public function activate( node:SpecialAbilityNode ):void
		{	
			if(wing1Entity == null)
				createWingEntities();
			super.setActive( true );
			flapping = !flapping;
			t = 0;
		}
		
		/**
		 * Turn wings into entities 
		 */
		private function createWingEntities():void
		{
			partEntity = CharUtils.getPart(super.entity, "pack");
			if (partEntity != null)
			{
				var partspatial:Spatial = partEntity.get(Spatial);
				
				if (partspatial != null)
				{
					var display:Display = partEntity.get(Display);
					var wing1:DisplayObject = display.displayObject.getChildByName("wing1");
					var wing2:DisplayObject = display.displayObject.getChildByName("wing2");
					
					wing1Entity = new Entity();
					wing1Entity.add(new Spatial(partspatial.x-16, partspatial.y-5));
					wing1Entity.add(new Display(wing1 as DisplayObjectContainer));
					super.group.addEntity(wing1Entity);
					
					wing2Entity = new Entity();
					wing2Entity.add(new Spatial(partspatial.x-40, partspatial.y-5));
					wing2Entity.add(new Display(wing2 as DisplayObjectContainer));
					super.group.addEntity(wing2Entity);
				}
			}
		}
		
		override public function deactivate( node:SpecialAbilityNode ):void
		{	
			super.setActive( false );
		}
		
		override public function update( node:SpecialAbilityNode, time:Number ):void
		{	
			if ((flapping) && (wing1Entity != null))
			{
				t += 0.3;
				wing1Entity.get(Spatial).rotation = 30*Math.sin(t);
				wing2Entity.get(Spatial).rotation = -wing1Entity.get(Spatial).rotation + 180;
			} else {
				wing1Entity.get(Spatial).rotation = 0;
				wing2Entity.get(Spatial).rotation = 180;
			}
		}
		
		private var partEntity:Entity;
		private var wing1Entity:Entity;
		private var wing2Entity:Entity;
		private var flapping:Boolean = false;
		private var t:Number;
	}
}