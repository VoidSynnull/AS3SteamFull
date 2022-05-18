package game.data.scene
{
	/**
	 * The SceneType class provides constant String values for scene types, which can be found
	 * in a scene's scene.xml under the "sceneType" tag.
	 * 
	 * @author Drew Martin
	 */
	public class SceneType
	{
		public static const DEFAULT:String			= "default";
		public static const MAINSTREET:String 		= "mainstreet";
		public static const CUTSCENE:String 		= "cutscene";
		public static const BILLBOARD:String 		= "billboard";
		public static const ADINTERIOR:String 		= "adinterior";		// ad interior scene
		public static const SHORTMAIN:String		= "shortmain";		// short island main street equivalent
		public static const NOWRAPPER:String		= "nowrapper";		// force no wrapper on default scene
	}
}