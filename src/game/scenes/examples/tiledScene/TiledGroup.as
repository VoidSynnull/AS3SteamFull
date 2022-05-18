package game.scenes.examples.tiledScene
{
	import flash.display.Bitmap;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.group.Group;
	
	import game.scenes.examples.tiledScene.components.TilesAsset;
	import game.scenes.examples.tiledScene.components.TilesData;
	import game.scenes.examples.tiledScene.systems.TilesSystem;
	import game.systems.SystemPriorities;
	
	public class TiledGroup extends Group
	{
		public function TiledGroup()
		{
			super();
		}
		
		public function setupGroup($group:Group, $container:DisplayObjectContainer):void{
			// initialize creator
			trace("initializeing TiledGroup");
			
			// add systems
			super.addSystem(new TilesSystem(this), SystemPriorities.render);
			
			_group = $group;
			_container = $container;
			
			// create and add necessary entities
			tiledEntity = new Entity();
			tiledEntity.add(new Id("tiles"));
			tiledEntity.add(new Spatial());
			tiledEntity.add(new Display(_container["tiledDisplay"]));
			tiledEntity.add(new TilesAsset(_container["tiledBuilding"] as MovieClip, 100, 100, 300, 300));
			tiledEntity.add(new TilesData());
			
			super.addEntity(tiledEntity);
			
			// ############ TEST CODE ###############
			/*
			for(var a:int = 0; a < TilesAsset(tiledEntity.get(TilesAsset)).tileAssetGrid.length; a++){
				for(var b:int = 0; b < TilesAsset(tiledEntity.get(TilesAsset)).tileAssetGrid[a].length; b++){
					for(var c:int = 0; c < TilesAsset(tiledEntity.get(TilesAsset)).tileAssetGrid[a][b].length; c++){
						var bitmap:Bitmap = TilesAsset(tiledEntity.get(TilesAsset)).tileAssetGrid[a][b][c];
						bitmap.x = c*100;
						bitmap.y = b*100;
						Display(tiledEntity.get(Display)).displayObject.addChild(bitmap);
					}
				}
			}
			
			for(var d:int = 0; d < TilesAsset(tiledEntity.get(TilesAsset)).displayObjects.length; d++){
				var testBitmap:Bitmap = TilesAsset(tiledEntity.get(TilesAsset)).displayObjects[d];
				//Display(tiledEntity.get(Display)).displayObject.addChild(testBitmap);
			}
			*/
			// ######################################
			
		}
		
		private var _group:Group;
		private var _container:DisplayObjectContainer;
		
		public var tiledEntity:Entity;
	}
}