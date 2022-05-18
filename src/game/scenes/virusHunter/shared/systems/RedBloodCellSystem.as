/*
import flash.events.Event;

var i:uint;
var bloodCells:Array = new Array();

addEventListener("enterFrame", update);

for (i=1; i<=20; i++) {
addBloodCell();
}

function addBloodCell() {
var bloodCell = new BloodCell();
addChild(bloodCell);
bloodCell.x = Math.random()*stage.stageWidth
bloodCell.y = Math.random()*stage.stageHeight;
bloodCells.push(bloodCell);
bloodCell.t = Math.random()*2*Math.PI;
bloodCell.turnSpeed = Math.random()*0.1 + 0.05;
bloodCell.rotation = Math.random()*360;
bloodCell.radius = 4;
bloodCell.vr = Math.random()*4 - 2;
bloodCell.scaleX = bloodCell.scaleY = Math.random()*0.25 + 0.75;
bloodCell.vx = -Math.random()*2 - 3;
bloodCell.vy = Math.random()*2 + 1;
}

function update(e:Event):void {
for (i=0; i<bloodCells.length; i++) {
var bc = bloodCells[i];
bc.t += bc.turnSpeed;
bc.side1.x = bc.radius*Math.sin(bc.t);
bc.side2.x = bc.radius*Math.sin(bc.t + Math.PI);
bc.side1.scaleX = Math.cos(bc.t);
bc.side2.scaleX = Math.cos(bc.t + Math.PI);
if (bc.side1.scaleX < 0 && bc.getChildIndex(bc.side1) > bc.getChildIndex(bc.side2)) {
bc.swapChildren(bc.side1, bc.side2);
}
else if (bc.side1.scaleX > 0 && bc.getChildIndex(bc.side1) < bc.getChildIndex(bc.side2)) {
bc.swapChildren(bc.side1, bc.side2);
}
bc.rotation += bc.vr;
bc.x += bc.vx;
bc.y += bc.vy;
if (bc.x < -50) {
bc.x = stage.stageWidth + 50;
}
if (bc.y > stage.stageHeight + 50) {
bc.y = -50;
}
}
}*/

package game.scenes.virusHunter.shared.systems
{
	import flash.display.MovieClip;
	
	import ash.core.Engine;
	import ash.tools.ListIteratingSystem;
	
	import game.scenes.virusHunter.shared.components.RedBloodCell;
	import game.scenes.virusHunter.shared.creators.EnemyCreator;
	import game.scenes.virusHunter.shared.nodes.RedBloodCellMotionNode;
	import game.util.EntityUtils;
	
	public class RedBloodCellSystem extends ListIteratingSystem
	{
		public function RedBloodCellSystem(creator:EnemyCreator)
		{
			super(RedBloodCellMotionNode, updateNode);
			_creator = creator;
		}
		
		private function updateNode(node:RedBloodCellMotionNode, time:Number):void
		{
			if (EntityUtils.sleeping(node.entity))
			{
				node.redBloodCell.state = node.redBloodCell.INACTIVE;
				node.entity.remove(RedBloodCell);
				_creator.releaseEntity(node.entity);
				return;
			}
			
			var cell:RedBloodCell = node.redBloodCell;
			var display:MovieClip = node.display.displayObject as MovieClip;
			display = display.cell;
			
			cell.angle += cell.turnSpeed;
			display.side1.x = cell.radius*Math.sin(cell.angle);
			display.side2.x = cell.radius*Math.sin(cell.angle + Math.PI);
			display.side1.scaleX = Math.cos(cell.angle);
			display.side2.scaleX = Math.cos(cell.angle + Math.PI);
			
			if (display.side1.scaleX < 0 && display.getChildIndex(display.side1) > display.getChildIndex(display.side2)) 
			{
				display.swapChildren(display.side1, display.side2);
			}
			else if (display.side1.scaleX > 0 && display.getChildIndex(display.side1) < display.getChildIndex(display.side2)) 
			{
				display.swapChildren(display.side1, display.side2);
			}
			
			if(node.damageTarget.damage > node.damageTarget.maxDamage)
			{
				node.redBloodCell.state = node.redBloodCell.DIE;
			}
			
			if(node.redBloodCell.state == node.redBloodCell.DIE)
			{
				if(node.spatial.scale <= 0)
				{
					node.redBloodCell.state = node.redBloodCell.INACTIVE;
					node.entity.remove(RedBloodCell);
					_creator.releaseEntity(node.entity);
					_creator.createRandomPickup(node.spatial.x, node.spatial.y, false);
				}
				else
				{
					node.spatial.scale -= .1;
				}
			}
		}
		
		override public function removeFromEngine(systemManager:Engine) : void
		{
			systemManager.releaseNodeList(RedBloodCellMotionNode);
			super.removeFromEngine(systemManager);
		}
		
		private var _creator:EnemyCreator;
	}
}