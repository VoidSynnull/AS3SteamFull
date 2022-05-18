package game.systems.actionChain.actions
{
	import ash.core.Entity;
	
	import engine.group.Group;
	
	import game.components.motion.Destination;
	import game.components.motion.MotionControl;
	import game.components.entity.Sleep;
	import game.components.motion.TargetEntity;
	import game.util.MotionUtils;
	import game.systems.actionChain.ActionCommand;
	import game.nodes.specialAbility.SpecialAbilityNode;

	// Turn off following
	public class StopFollowAction extends ActionCommand {
		
		private var follower:Entity;
		private var unlockControl:Boolean;
		
		private var _restoreInputFollow:Boolean;
		private var _ignoreOffscreenSleep:Boolean = false;

		/**
		 * Turn off following 
		 * @param follower			Entity that is to stop following
		 * @param isPlayer			Flag that means the follower is the player -> input will be restored (but not unlocked) on action complete
		 * @param unlockControl		Flag that means MotionControl will be unlocked
		 */
		public function StopFollowAction( follower:Entity, isPlayer:Boolean = false, unlockControl:Boolean = false )
		{
			if ( isPlayer )
			{
				this._ignoreOffscreenSleep = true;
				this._restoreInputFollow = true;
			}
			
			this.follower = follower;
			this.unlockControl = unlockControl;
		} 

		override public function preExecute( callback:Function, group:Group, node:SpecialAbilityNode = null ):void 
		{
			if ( _restoreInputFollow ) 
			{
				MotionUtils.followInputEntity( follower, group.shellApi.inputEntity, true );
			} 
			else 
			{
				follower.remove(TargetEntity);
			}
			follower.remove(Destination);	// TODO :: Not sure about removing this here? - bard
			
			var motionControl:MotionControl = follower.get( MotionControl );
			if( motionControl )
			{
				motionControl.forceTarget = false;
				motionControl.moveToTarget = false;
				motionControl.lockInput = !unlockControl;
			}

			var sleep:Sleep = follower.get( Sleep );
			if ( sleep ) 
			{
				sleep.ignoreOffscreenSleep = _ignoreOffscreenSleep;
			}

			callback();
		}
	}
}