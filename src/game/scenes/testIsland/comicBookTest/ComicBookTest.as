package game.scenes.testIsland.comicBookTest
{
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import engine.components.Interaction;
	import engine.creators.InteractionCreator;
	import engine.group.Group;
	
	import game.comicViewer.groups.ComicViewerPopup;
	import game.creators.ui.ToolTipCreator;
	import game.scene.template.PlatformerGameScene;
	import game.util.EntityUtils;
	
	public class ComicBookTest extends PlatformerGameScene
	{
		public function ComicBookTest()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/testIsland/comicBookTest/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{
			var door:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["door1"]);
			var inter:Interaction = InteractionCreator.addToEntity(door,[InteractionCreator.CLICK]);
			inter.click.add(openComic);
			ToolTipCreator.addToEntity(door);
			super.loaded();
		}
		
		private function openComic(click:Entity):void
		{
			var comic:ComicViewerPopup = new ComicViewerPopup(overlayContainer);
			comic.groupPrefix = "comicViewer/";
			comic.comicPrefix = "comics/Einstein/";
			comic.pageForward.add(onPageForward);
			this.addChildGroup(comic);
			
		}
		
		private function onPageForward(popup:ComicViewerPopup, page:int, totalPages:int):void
		{
			if(page == totalPages)
			{
				trace("Working as intended.");
				popup.pageForward.remove(onPageForward);
				popup.removed.addOnce(giveItem);
			}
		}
		
		private function giveItem(group:Group):void
		{
			this.shellApi.getItem(3014, "store", true);
		}
		
		override public function destroy():void
		{
			
			super.destroy();	
		}
	}
}