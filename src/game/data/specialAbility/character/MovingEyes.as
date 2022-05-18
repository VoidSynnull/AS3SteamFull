// Used by:
// 

package game.data.specialAbility.character
{
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	

	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.util.DisplayUtils;
	import game.util.SkinUtils;
	
	/**
	 * Facial Part with eyes that respond to mouse
	 */
	public class MovingEyes extends SpecialAbility
	{
		override public function init(node:SpecialAbilityNode):void
		{
			super.init(node);
			
			var container:DisplayObjectContainer = null;
			var pants:Entity = SkinUtils.getSkinPartEntity(node.entity,SkinUtils.FACIAL);
			if(pants)
			{
			//	var disp:Display = pants.get(Display);
				//disp.displayObject.parent.setChildIndex(disp.displayObject,disp.displayObject.parent.numChildren - 4);
			}
			super.setActive(true);
		}
		
		override public function update(node:SpecialAbilityNode, time:Number):void
		{
			super.setActive(true);
			var pants:Entity = SkinUtils.getSkinPartEntity(node.entity, SkinUtils.FACIAL);
			var disp:Display = pants.get(Display);
			var point:Point = DisplayUtils.mouseXY(Display(entity.get(Display)).displayObject);
			
			if(super.entity.get(Spatial).scaleX > 0)
			{
				var a1:Number = point.y - disp.displayObject.eye.y ;
				var b1:Number = point.x - disp.displayObject.eye.x
				var radians1:Number = Math.atan2(b1,a1);
				var degrees1:Number = (radians1/2) / (Math.PI / 180);
				disp.displayObject.eye.rotation = degrees1;
				
				var a2:Number =   point.y - disp.displayObject.eye2.y;
				var b2:Number =  point.x - disp.displayObject.eye2.x ;
				var radians2:Number = Math.atan2(b2,a2);
				var degrees2:Number = (radians2/2) / (Math.PI / 180);
				disp.displayObject.eye2.rotation = degrees2;
			}
			else
			{
				var a3:Number = point.y - disp.displayObject.eye.y ;
				var b3:Number = disp.displayObject.eye.x - point.x;
				var radians3:Number = Math.atan2(b3,a3);
				var degrees3:Number = (radians3/2) / (Math.PI / 180);
				disp.displayObject.eye.rotation = degrees3;
				
				var a4:Number =   point.y - disp.displayObject.eye2.y;
				var b4:Number = disp.displayObject.eye2.x - point.x ;
				var radians4:Number = Math.atan2(b4,a4);
				var degrees4:Number = (radians4/2) / (Math.PI / 180);
				disp.displayObject.eye2.rotation = degrees4;
			}
			
		}
		
		override public function deactivate( node:SpecialAbilityNode ):void
		{
			super.setActive( false );
		}	
		
	}
}


