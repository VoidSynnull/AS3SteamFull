package game.util
{
	import engine.group.DisplayGroup;

	public class GroupUtils
	{
		/**
		 * Produces a 'groupPrefix' string that matches the qualified class name of the instance.
		 * ex : game.scenes.examples.sceneName::SceneName > scenes/examples/sceneName/
		 */
		public static function generateGroupPrefixFromClassPath(instance:*):String
		{
			var scenePath:String = ClassUtils.getNameByObject(instance);
			var scenePathArray:Array = scenePath.split(".");
			var sceneName:String = scenePathArray[scenePathArray.length - 1];
			// remove "game." from beginning of path
			scenePathArray.shift();
			// remove "::SceneName" from end of path
			scenePathArray[scenePathArray.length - 1] = sceneName.split("::")[0];
			var newPath:String = scenePathArray.join("/") + "/";
			
			return(newPath);
		}
		
		public static function replaceGroupPrefixString(url:String, group:DisplayGroup):String
		{
			var pattern:String = "GROUP_PREFIX";
			var prefix:String = group.groupPrefix.substring(0, group.groupPrefix.length - 1);  // removing final "/"
			
			// ONLY changes url if the pattern is found.
			url = url.replace(pattern, prefix)
			
			return(url);
		}
	}
}