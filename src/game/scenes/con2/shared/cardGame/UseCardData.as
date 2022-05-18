package game.scenes.con2.shared.cardGame
{
	import ash.core.Entity;

	public class UseCardData
	{
		public var card:CCGCard;
		public var attacking:Boolean;
		public var blocked:Boolean;
		public var reversed:Boolean;
		public var opponent:CCGUser;
		public var user:CCGUser;
		public var entity:Entity;
		
		public function UseCardData(entity:Entity, attacking:Boolean, blocked:Boolean, opponent:CCGUser, user:CCGUser)
		{
			this.entity = entity;
			if(entity != null)
				card = entity.get(CCGCard);
			this.attacking = attacking;
			this.blocked = blocked;
			this.opponent = opponent;
			this.user = user;
			reversed = false;
		}
	}
}