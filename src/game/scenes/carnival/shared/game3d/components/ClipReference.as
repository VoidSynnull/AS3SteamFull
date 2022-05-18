package game.scenes.carnival.shared.game3d.components {

	import flash.display.MovieClip;
	
	import ash.core.Component;

	/**
	 * No easy way right now for an entity to reference an arbitrary movie clip.
	 */
	public class ClipReference extends Component {

		public var clip:MovieClip;

		public function ClipReference( ref:MovieClip ) {

			super();

			this.clip = ref;

		}

	} // End ClipReference

} // End package