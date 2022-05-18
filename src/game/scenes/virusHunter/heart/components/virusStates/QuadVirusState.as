package game.scenes.virusHunter.heart.components.virusStates {

	import ash.core.Entity;
	
	import ash.core.Component;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.scenes.virusHunter.heart.components.QuadVirus;

	public class QuadVirusState extends Component {

		protected var virus:Entity;
		protected var quadVirus:QuadVirus;

		protected var spatial:Spatial;
		protected var motion:Motion;

		// Not very precise, but basically triggers when/if a full sequence of a state has completed.
		public var onStateDone:Function;

		public function QuadVirusState( virus:Entity ) {

			spatial = virus.get( Spatial ) as Spatial;
			motion = virus.get( Motion ) as Motion;

			quadVirus = virus.get( QuadVirus ) as QuadVirus;

			this.virus = virus;

		} //

		public function start():void {
		}

		public function update( time:Number ):void {
		} //

	} // End class

} // End package