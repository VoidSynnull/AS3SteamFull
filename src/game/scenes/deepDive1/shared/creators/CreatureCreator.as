package game.scenes.deepDive1.shared.creators
{
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	
	import game.components.motion.TargetSpatial;
	import game.components.motion.RotateControl;
	import game.scenes.virusHunter.shared.components.EnemyEye;
	import game.util.EntityUtils;

	public class CreatureCreator
	{
		public function CreatureCreator()
		{
		}
		
		public function addEyes(parent:Entity, container:MovieClip, target:Spatial = null):void
		{
			if(parent != null && container != null)
			{
				var total:Number = container.numChildren;
				var eyeClip:MovieClip;
				var entity:Entity;
				
				for (var n:Number = total - 1; n >= 0; n--)
				{
					eyeClip = container.getChildAt(n) as MovieClip;

					if (eyeClip != null)
					{
						if(eyeClip.name.indexOf("eye") > -1)
						{
							entity = new Entity();
							entity.add(new Spatial(0, 0));
							entity.add(new Display(eyeClip.pupil));
							entity.add(new EnemyEye());
							entity.add(new Id(eyeClip.name));
							
							if(target != null)
							{
								entity.add(new TargetSpatial(target));
								var rotateControl:RotateControl = new RotateControl();
								rotateControl.origin = parent.get(Spatial);
								rotateControl.targetInLocal = false;
								rotateControl.ease = .2;
								entity.add(rotateControl);
							}
							
							EntityUtils.addParentChild(entity, parent, true);
						}
					}
				}
			}
		}
	}
}