package game.components.entity.character.part
{	

	import ash.core.Component;
	import game.data.character.part.PartMetaData;
	import org.osflash.signals.Signal;
	
	public class Part extends Component
	{
		public function Part()
		{
			loaded = new Signal( Part );
		}
		
		public var id : String;			// id for specific part (e.g. arm1, hand2, foot2, facial, shirt, bodySkin )
		public var type : String;		// part type, used to retrieve assest (e.g. hand, foot, facial, shirt, bodySkin )
		public var jointId : String;	// id of joint that part i
		public var springTo : String;
		public var loaded:Signal;
	}
}
