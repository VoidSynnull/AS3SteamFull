package game.components.motion.nape
{
	import ash.core.Component;
	
	import nape.constraint.PivotJoint;
	
	public class NapePivotJoint extends Component
	{
		public function NapePivotJoint(pivotJoint:PivotJoint)
		{
			this.pivotJoint = pivotJoint;
		}
		
		public var pivotJoint:PivotJoint;
	}
}