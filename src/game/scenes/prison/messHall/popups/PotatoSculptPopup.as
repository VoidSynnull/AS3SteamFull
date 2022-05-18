package game.scenes.prison.messHall.popups
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	
	import game.components.motion.SpatialToMouse;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ToolTipCreator;
	import game.scenes.prison.shared.particles.ChiselBlast;
	import game.systems.motion.SpatialToMouseSystem;
	import game.ui.popup.Popup;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	import game.util.SceneUtil;
	import game.util.TweenUtils;
	
	public class PotatoSculptPopup extends Popup
	{
		public function PotatoSculptPopup(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function init(container:DisplayObjectContainer=null):void
		{
			super.init(container);
			
			this.groupPrefix = "scenes/prison/messHall/popups/";
			this.pauseParent = true;
			this.darkenBackground = true;
			this.darkenAlpha = .75;
			
			load();
		}
		
		override public function load():void
		{
			this.loadFiles(["potatoSculptPopup.swf"], false, true, loaded);
		}
		
		override public function loaded():void
		{
			this.screen = getAsset("potatoSculptPopup.swf", true) as MovieClip;
			this.letterbox(screen.content, new Rectangle(0, 0, 860,560), false);
			
			setupChiselSpots();
			
			super.loadCloseButton();
			super.loaded();
			
			var spoonClip:MovieClip = screen.content["spoon_sharpened"];
			spoonClip.mouseChildren = false;
			spoonClip.mouseEnabled = false;
			_spoonEntity = EntityUtils.createSpatialEntity(this, spoonClip);
			_spoonEntity.add(new SpatialToMouse(screen.content));
			_spoonEntity.add(new SpatialAddition());
			this.addSystem(new SpatialToMouseSystem());
		}
		
		private function setupChiselSpots():void
		{
			_dictionary = new Dictionary();
			_dictionary["click0"] = new Array();
			_dictionary["click1"] = new Array();
			_dictionary["click2"] = new Array();
			_dictionary["click3"] = new Array();
			
			for each(var child:MovieClip in screen.content)
			{
				if(child.name.indexOf("chisel") != -1)
				{
					var newChiselSpot:Entity = EntityUtils.createSpatialEntity(this, child);					
					if(child.name.indexOf("_0") != -1)
						_dictionary["click0"].push(newChiselSpot);
					
					if(child.name.indexOf("_1") != -1)
						_dictionary["click1"].push(newChiselSpot);
					
					if(child.name.indexOf("_2") != -1)
						_dictionary["click2"].push(newChiselSpot);
					
					if(child.name.indexOf("_3") != -1)
						_dictionary["click3"].push(newChiselSpot);
				}
				else if(child.name.indexOf("click") != -1)
				{
					var clickSpot:Entity = EntityUtils.createSpatialEntity(this, child);
					clickSpot.add(new Id(child.name));
					clickSpot.get(Display).alpha = 0;
					var interaction:Interaction = InteractionCreator.addToEntity(clickSpot, [InteractionCreator.CLICK]);
					interaction.click.add(spotClicked);
					ToolTipCreator.addToEntity(clickSpot);
				}
			}
		}
		
		private function spotClicked(clickPart:Entity):void
		{
			_numClicks++;
			var point:Point = new Point(screen.content.mouseX, screen.content.mouseY);
			var chiselBlast:ChiselBlast = new ChiselBlast();
			chiselBlast.init(6, 10, 3, 0xE6E2C4);
			EmitterCreator.create(this, screen.content, chiselBlast, point.x, point.y);
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "dirt_break_0" + GeomUtils.randomInt(1,4) + ".mp3");
			
			CharUtils.lockControls(shellApi.player, true);
			TweenUtils.entityTo(_spoonEntity, SpatialAddition, .1, {y:-15, onComplete:tweenBack});
			
			if(_numClicks%2 == 0)
			{
				var id:String = clickPart.get(Id).id;
				var array:Array = _dictionary[id];
				if(array)
				{
					var chiselPart:Entity = findClosest(point, array);
					removeFromAllDict(chiselPart);
					removeEntity(chiselPart);
					
					if(array.length == 0)
					{
						clickPart.get(Interaction).click.removeAll();
						removeEntity(clickPart);
						_dictionary[id] = null;
						
						_arraysFinished++;
						if(_arraysFinished == 4)
						{
							SceneUtil.lockInput(this, true);
							completed = true;
							SceneUtil.delay(this, 1, close);
						}
					}
				}
			}
		}
		
		private function tweenBack():void
		{
			TweenUtils.entityTo(_spoonEntity, SpatialAddition, .1, {y:0});
			CharUtils.lockControls(shellApi.player, false, false);
		}
		
		// remove entity from all arrays, some are in multiple
		private function removeFromAllDict(entity:Entity):void
		{
			for each(var array:Array in _dictionary)
			{
				if(array)
				{
					var index:int = array.indexOf(entity)
					if(index != -1)
					{
						array.splice(index,1);
					}
				}
			}
		}
		
		// find the closest entity to where the person clicked
		private function findClosest(mousePoint:Point, array:Array):Entity
		{
			var closest:Entity = null;
			var closerNum:Number = -1;
			
			for each(var entity:Entity in array)
			{
				var spatial:Spatial = entity.get(Spatial);
				var dist:Number = GeomUtils.distSquared(spatial.x, spatial.y, mousePoint.x, mousePoint.y);
				if(closest == null || dist < closerNum)
				{
					closerNum = dist;
					closest = entity;
				}				
			}
			
			return closest;
		}
		
		override public function close(removeOnClose:Boolean=true, onClosedHandler:Function=null):void
		{
			SceneUtil.lockInput(this, false, false);
			super.close(removeOnClose, onClosedHandler);
		}
		
		public var completed:Boolean = false; // check this Karn
		private const NUM_CHISEL_SPOTS:Number = 32;
		
		private var _arraysFinished:int = 0;
		private var _dictionary:Dictionary;
		private var _numClicks:int;
		private var _spoonEntity:Entity;
	}
}