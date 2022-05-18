package game.scenes.custom.LoopingPopupSystems
{
	import ash.core.Component;
	
	import game.components.entity.MotionMaster;
	
	public class LoopingSegmentPiece extends Component
	{
		public var master:MotionMaster;
		public function LoopingSegmentPiece(master:MotionMaster)
		{
			this.master = master;
		}
	}
}