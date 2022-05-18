package game.scenes.carnival.hauntedLab.components
{	
	import flash.geom.Point;
	
	import ash.core.Component;
	import ash.core.Entity;

	public class PuppetMonster extends Component
	{
		public var target:Point;
		public var cageEntities:Vector.<Entity>;
		
		public function PuppetMonster(target:Point, cageEntities:Vector.<Entity>)
		{
			this.target = target;
			this.cageEntities = cageEntities;
		}
	}
}