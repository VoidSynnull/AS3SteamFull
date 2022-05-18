package game.scenes.viking.shared.balanceGame
{
	import ash.core.Entity;
	
	import engine.components.Motion;
	
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	
	public class BalanceGameSystem extends GameSystem
	{
		private var player:Entity;
		private var playerDelta:Number = 0;
		
		public function BalanceGameSystem()
		{
			super(BalanceSegementNode, nodeUpdate, nodeAdd);
			this._defaultPriority = SystemPriorities.move;
		}
		
		public function nodeAdd(node:BalanceSegementNode):void
		{
			this.player = node.entity.group.shellApi.player;
			
			//trace("BALANCE NODE ADDED");
		}
		
		public function nodeUpdate(node:BalanceSegementNode, time:Number):void
		{
			if(node.balance.tilting){
				var tilt:Number = node.balance.findTotalTilt();
				//trace("TOTAL_TILT: " + tilt);
				if(Math.abs(tilt) < node.balance.tiltLimit ){
					if(Math.abs(tilt) > node.balance.warningLimit){
						node.balance.warningSignal.dispatch(true);
					}else{
						node.balance.warningSignal.dispatch(false);
					}
					var pMotion:Motion = player.get(Motion);
					playerDelta = pMotion.velocity.x;
					var tiltChange:Number = 0;
					if(playerDelta > 0){
						tiltChange = -node.balance.tiltSpeed;
					}
					else if(playerDelta < 0){
						tiltChange = node.balance.tiltSpeed;
					}
					else{
						// accell lightly in current direction while standing still
						var t:Number = ( tilt > 0 ) ? 1 : -1;
						tiltChange = t * node.balance.tiltSpeed * 0.7;
					}				
					node.balance.addTiltForce(tiltChange);
					
				}else{
					// failure
					node.balance.stopTilt();
					node.balance.failSignal.dispatch();
				}
			}else{
				node.balance.stopTilt();
			}
		}
		
		
		
		
		
		
		
		
	}
}