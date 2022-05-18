package game.scenes.virusHunter.heart.components.virusActions {

	import ash.core.Entity;
	
	import ash.core.Component;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.scenes.virusHunter.heart.components.QuadVirus;

	public class VirusAction extends Component {

		public var onActionDone:Function;

		public var timer:Number;
		public var phase:int;

		protected var virus:Entity;
		protected var quadVirus:QuadVirus;

		protected var spatial:Spatial;
		protected var motion:Motion;

		public function VirusAction( virus:Entity ) {

			this.virus = virus;
			quadVirus = virus.get( QuadVirus );

			spatial = virus.get( Spatial );
			motion = virus.get( Motion );

			timer = 0;

		} //

		public function start( doneFunc:Function=null ):void {

			onActionDone = doneFunc;

		}

		public function update( time:Number ):void {
		} //

	} // End class

} // End package