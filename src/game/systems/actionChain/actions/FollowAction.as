package game.systems.actionChain.actions
{
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.group.Group;
	
	import game.util.CharUtils;
	import game.systems.actionChain.ActionCommand;
	import game.nodes.specialAbility.SpecialAbilityNode;

	// Follow entity
	public class FollowAction extends ActionCommand
	{
		private var follower:Entity;
		private var leader:Entity;
		private var minDist:Point;

		/**
		 * Follow entity 
		 * @param follower		Entity that follows
		 * @param leader		Entity to follow
		 * @param minDist		Minimum distance that triggers that the target has been reached
		 */
		public function FollowAction( follower:Entity, leader:Entity, minDist:Point = null ) 
		{
			this.follower = follower;
			this.leader = leader;
			this.minDist = minDist;
		}

		override public function preExecute( callback:Function, group:Group, node:SpecialAbilityNode = null ):void 
		{
			CharUtils.followEntity( follower, leader, minDist );
			callback();
		}
	}
}