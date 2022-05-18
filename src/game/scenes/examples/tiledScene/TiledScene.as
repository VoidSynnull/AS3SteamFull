package game.scenes.examples.tiledScene
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import game.scene.template.PlatformerGameScene;
	import game.scenes.examples.tiledScene.components.TilesData;
	
	public class TiledScene extends PlatformerGameScene
	{
		public function TiledScene()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/examples/tiledScene/";
			
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
			super.loaded();
			_tiledGroup = new TiledGroup();
			super.addChildGroup(_tiledGroup);
			_tiledGroup.setupGroup(this, this._hitContainer);
			
			super.shellApi.eventTriggered.add(handleEventTriggered);
		}
		
		private function handleEventTriggered(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			switch(event){
				case "talkedToNPC":
					// clear old building
					var display:MovieClip = super._hitContainer["tiledDisplay"] as MovieClip;
					while(display.numChildren){
						display.removeChildAt(0);
					}
					// randomize building
					TilesData(_tiledGroup.tiledEntity.get(TilesData)).randomizeBuilding();
					break;
			}
		}
		
		private var _tiledGroup:TiledGroup;
	}
}

