package game.data.animation.entity.character.poptropolis 
{
	import game.data.animation.entity.character.Default;

	public class ShotputAnim extends Default
	{
		private const LABEL_START_PARTICLES:String = "startParticles";
		private const LABEL_STOP_PARTICLES:String = "stopParticles";
		private const LABEL_START:String = "start";
		private const LABEL_LAUNCH:String = "launch";
		
		public function ShotputAnim()
		{
			super.characterXmlPath = super.XML_PATH + super.TYPE_HUMAN + "poptropolis/shotput" + ".xml";
		}
	}
}