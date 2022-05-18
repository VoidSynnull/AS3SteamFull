package game.data.specialAbility.store
{
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	
	import game.data.specialAbility.character.PlaceObject;
	import game.util.TimelineUtils;
	
	public class PlaceFlare extends PlaceObject
	{
		public function PlaceFlare()
		{
			super();
		}
		
		override protected function additionalSetup(groundEntity:Entity):void
		{
			var display:Display = groundEntity.get(Display);
			
			var clip:MovieClip = display.displayObject;
			clip.mouseEnabled = false;
			clip.mouseChildren = false;
			
			TimelineUtils.convertAllClips(clip, null, groundEntity.group, true, 32, groundEntity);
		}
	}
}