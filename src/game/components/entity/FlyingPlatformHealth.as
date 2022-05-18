package game.components.entity
{
	import ash.core.Component;
	
	public class FlyingPlatformHealth extends Component
	{
		private var _health:uint = 0;
		private var _loseHandler:Function;
		private var _hitHandler:Function;
		private var _feedBackHandler:Function;
		
		// flags for hitting player or npc
		public var playerHit:Boolean = false;
		public var npcHit:Boolean = false;
		
		public function FlyingPlatformHealth( numHits:uint, loseHandler:Function, hitHandler:Function = null, feedBackHandler:Function = null)
		{
			_health = numHits;
			_loseHandler = loseHandler;
			_hitHandler = hitHandler;
			_feedBackHandler = feedBackHandler;
		}
		
		public function calculateHits(fromNPC:Boolean = false):Boolean
		{
			// if player hit or npc hit when player not hit
			if ((!fromNPC && playerHit) || (fromNPC && npcHit && !playerHit))
			{
				// decrement health
				if (_health > 0)
					_health -= 1;
				// check dead status
				var isDead:Boolean = _health <= 0 ? true : false;
				// reset hit booleans
				npcHit = false;
				playerHit = false;
				trace("flying platform hit: health:" + _health);
				
				// trigger hit handler
				if (_hitHandler)
					_hitHandler(_health);
				return isDead;
			}
			return false;
		}
		
		public function handleLose():void
		{
			_loseHandler();
		}
		
		public function handleFeedBack():void
		{
			if(_feedBackHandler)
				_feedBackHandler();
		}
	}
}