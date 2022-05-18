package game.scenes.mocktropica.classroom
{
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.managers.SoundManager;
	
	import game.components.particles.Flame;
	import game.creators.ui.ToolTipCreator;
	import game.data.ui.ToolTipType;
	import game.systems.SystemPriorities;
	import game.systems.particles.FlameSystem;
	import game.ui.popup.Popup;
	import game.util.AudioUtils;
	import game.util.EntityUtils;
	
	
	public class PoemPopup extends Popup
	{
		public function PoemPopup(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function destroy():void
		{
			// call the super class's 'destroy()' method as well to finish cleanup of this group which removes any entites and systems specific to this group, as well as removing the groupContainer.
			_fireAudio.stop(SoundManager.EFFECTS_PATH + "torch_fire_01_L.mp3");
			super.destroy();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.darkenBackground = true;
			super.groupPrefix = "scenes/mocktropica/classroom/";
			super.init(container);
			load();
		}		
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.shellApi.fileLoadComplete.addOnce(loaded);
			super.loadFiles(new Array("poemPopup.swf"));
		}
		
		// all assets ready
		override public function loaded():void
		{			
			super.screen = super.getAsset("poemPopup.swf", true) as MovieClip;
			//super.loadCloseButton();
			//super.layout.centerUI( super.screen.content );	
			
			_flame = MovieClip( MovieClip(super.screen.content).flame);
			_poem = MovieClip( MovieClip(super.screen.content).poem);
			_poemEnitity = EntityUtils.createSpatialEntity( this, _poem );
			_bound_rect = MovieClip( MovieClip(super.screen.content).bound_rect);
			
			bounds = new Rectangle();
			bounds.x = _bound_rect.x + (_poem.width * .5) - (_bound_rect.width * .5);
			bounds.y = _bound_rect.y + (_poem.height * .5) - (_bound_rect.height * .5);
			bounds.width = _bound_rect.width - _poem.width;
			bounds.height = _bound_rect.height - _poem.height;
			
			_poem.addEventListener(MouseEvent.MOUSE_DOWN, dragPoem);
			_poem.addEventListener(MouseEvent.MOUSE_UP, dropPoem);
			
			ToolTipCreator.addToEntity(_poemEnitity, ToolTipType.TARGET);	
			
			_fireSoundEntity = AudioUtils.createSoundEntity("_fireSoundEntity");	
			_fireAudio = new Audio();
			_fireSoundEntity.add(_fireAudio);			
			super.addEntity(_fireSoundEntity);
			
			super.loaded();
		}
		
		private function dragPoem(event:MouseEvent):void {
			_poem.startDrag(false, bounds);
		}
		private function dropPoem(event:MouseEvent):void {
			_poem.stopDrag();
		}
		
		public function doBurn():void{
		
			var clip:MovieClip;
			var entity:Entity;			

			clip = super.screen["flame"];		
			clip.alpha = 1;
			this.addSystem(new FlameSystem(), SystemPriorities.lowest);				
			var flames:Array = [clip["flame1"], clip["flame2"]];			
				
			for(var i:int = 0; i < flames.length; i++)
			{
					
				entity = new Entity();
					
				if( i == 0 )
				{
					entity = EntityUtils.createSpatialEntity( this, clip );
					EntityUtils.getDisplay( entity ).alpha = .65;
					entity.add( new Flame( flames[ i ], true ));
						
				}
				else
				{
					entity.add( new Flame( flames[ i ], false ));
					this.addEntity(entity);
						
				}
			}
			
			_fireAudio.play(SoundManager.EFFECTS_PATH + "torch_fire_01_L.mp3", true);
			
		}
		
		private var _poemEnitity:Entity;
		private var _poem:MovieClip;
		private var _flame:MovieClip;
		private var _bound_rect:MovieClip;
		private var bounds:Rectangle;
		private var _fireSoundEntity:Entity;
		private var _fireAudio:Audio;
	}
}




