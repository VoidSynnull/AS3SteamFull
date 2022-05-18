package game.components.motion.nape
{
	import ash.core.Component;
	import nape.phys.Body;
	
	public class NapeMotion extends Component
	{
		public function NapeMotion(body:Body)
		{
			this.body = body;
		}
		
		public var body:Body;
	}
}