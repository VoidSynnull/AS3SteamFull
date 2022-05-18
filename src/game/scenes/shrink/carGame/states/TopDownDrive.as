package game.scenes.shrink.carGame.states
{
	public class TopDownDrive extends TopDownDriverState
	{
		public function TopDownDrive()
		{
			super.type = TopDownDriverState.DRIVE;
		}
		
		/**
		 * Start the state
		 */
		override public function start():void
		{
			node.spatial.scaleX = 1;
			_scaleIncrementor = .0001;
			node.motionMaster.maxVelocity.x = 700;
			
			super.updateStage = carDriveMovement;
		}
		
		override public function update( time:Number ):void
		{
			super.update( time );
			super.updateStage();
		}
	}
}