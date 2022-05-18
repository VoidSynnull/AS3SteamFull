package game.data.animation.entity.character 
{

	public class WeightLifting extends Default
	{
		private const LABEL_LIFT:String = "lift";
		private const LABEL_HIGH_POINT:String = "highPoint";
		private const LABEL_DROP:String = "drop";
		
		public function WeightLifting()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "weightLifting" + ".xml";
		}
	}
}