package game.data.specialAbility.islands.cavern
{	
	import flash.display.MovieClip;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	
	import game.components.ui.Button;
	import game.creators.ui.ButtonCreator;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.scenes.cavern1.shared.components.Magnet;
	import game.scenes.cavern1.shared.components.MagneticData;
	
	public class MagBelt extends SpecialAbility
	{
		public var _radius:Number = 0;
		public var _canRepel:Boolean = false;
		
		private var _magneticData:MagneticData;
		private var _attract:Entity;
		private var _repel:Entity;
		
		override public function activate(node:SpecialAbilityNode):void
		{
			_magneticData = new MagneticData(0, _radius);
			node.entity.add(_magneticData);
			node.entity.add(new Magnet(400));
			
			this.data.isActive = true;
			trace("Activate MagBelt!", _radius, _canRepel);
			_canRepel = true;
			this.shellApi.loadFile(this.shellApi.assetPrefix + "scenes/cavern1/shared/beltUI.swf", beltUILoaded, node);
		}
		
		private function beltUILoaded(clip:MovieClip, node:SpecialAbilityNode):void
		{
			if(clip)
			{
				if(this.data.isActive)
				{
					//Align UI to the bottom left of the screen with 10 pixels buffer space.
					this.shellApi.currentScene.overlayContainer.addChildAt(clip, 0);
					var bounds:Rectangle = clip.getBounds(clip.parent);
					clip.x = -bounds.left + 10;
					clip.y = -bounds.bottom - 10 + this.shellApi.viewportHeight;
					
					var button:MovieClip;
					
					//Attract button
					button = clip.getChildByName("attract") as MovieClip;
					_attract = ButtonCreator.createButtonEntity(button, node.entity.group, toggleMagnetism);
					Button(_attract.get(Button)).value = -1;
					
					//Repel button
					button = clip.getChildByName("repel") as MovieClip;
					_repel = ButtonCreator.createButtonEntity(button, node.entity.group, toggleMagnetism);
					Button(_repel.get(Button)).value = 1;
					if(!_canRepel)
					{
						Display(_repel.get(Display)).visible = false;
					}
				}
			}
		}
		
		override public function deactivate(node:SpecialAbilityNode):void
		{
			this.data.isActive = false;
		}
		
		private function toggleMagnetism(entity:Entity):void
		{
			var polarity:int = Button(entity.get(Button)).value;
			
			if(_magneticData)
			{
				//Attract was clicked
				if(polarity == 1)
				{
					if(_magneticData.polarity <= 0)
					{
						_magneticData.polarity = 1;
					}
					else
					{
						_magneticData.polarity = 0;
					}
				}
				//Repel was clicked
				else
				{
					if(_magneticData.polarity >= 0)
					{
						_magneticData.polarity = -1;
					}
					else
					{
						_magneticData.polarity = 0;
					}
				}
				
				Button(_attract.get(Button)).isSelected = _magneticData.polarity < 0;
				Button(_repel.get(Button)).isSelected = _magneticData.polarity > 0;
			}
		}
		
		private function toggleRepel(entity:Entity):void
		{
			
		}
	}
}