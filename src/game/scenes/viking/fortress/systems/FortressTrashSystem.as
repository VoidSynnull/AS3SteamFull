package game.scenes.viking.fortress.systems 
{
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Spatial;
	
	import game.scenes.viking.fortress.Fortress;
	import game.scenes.viking.fortress.nodes.FortressTrashNode;
	import game.systems.SystemPriorities;
	import game.util.Utils;
	
	public class FortressTrashSystem extends System
	{
		private var _trashes:NodeList;
		private var startX:Number = 695;
		private var startY:Number = 888;
		
		public function FortressTrashSystem()
		{
			super._defaultPriority = SystemPriorities.update;
		}
		
		override public function addToEngine( systemsManager:Engine ):void
		{
			_trashes = systemManager.getNodeList( FortressTrashNode );
		}
		
		override public function update( time:Number ):void
		{
			var trash:FortressTrashNode;
			
			for(trash = _trashes.head; trash; trash = trash.next) {		
				if(trash.trash.active){
					if(trash.spatial.x < 651){
						trash.trash.vy += 0.3;
						trash.trash.vx += 0.001;
					}
					trash.spatial.x += trash.trash.vx;
					trash.spatial.y += trash.trash.vy;	
					trash.spatial.rotation -= trash.trash.vr;
					
					if(trash.spatial.y > 2000){
						trash.trash.active = false;
					}
				}
			}
			
		}
		
		public function startDump():void {
			var trash:FortressTrashNode;
			
			for(trash = _trashes.head; trash; trash = trash.next) {		
				trash.spatial.x = startX + Utils.randInRange(0, 200);
				trash.spatial.y = startY + Utils.randInRange(-3, 3);
				trash.trash.vx = -5 + Utils.randInRange(-1, 1);
				trash.trash.vy = 0.2;
				trash.trash.vr = 3 + Utils.randInRange(-1, 2);
				trash.trash.active = true;
				trash.display.displayObject.gotoAndStop(Math.ceil(Math.random()*12));
			}
		}
		
		override public function removeFromEngine( systemsManager:Engine ):void
		{
			systemsManager.releaseNodeList( FortressTrashNode );
			_trashes = null;
		}
	}
}




