package game.components.smartFox
{
	import com.smartfoxserver.v2.entities.data.ISFSObject;
	
	import ash.core.Component;
	
	/**
	 * Component for any basic object managed by smartfox in a scene.
	 */
	
	public class SFSceneObject extends Component
	{
		public var sfsObject:ISFSObject;
	}
}