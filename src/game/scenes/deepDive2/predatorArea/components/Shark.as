package game.scenes.deepDive2.predatorArea.components
{
	import flash.geom.Point;
	
	import ash.core.Component;
	import ash.core.Entity;
	
	import org.osflash.signals.Signal;
	
	public class Shark extends Component
	{
		public var swimPoint:Point; // if exists, shark will swim to point
		public var attackPoint:Point; // if exists, shark will charge and chomp at the point
		public var bite:Signal = new Signal(); // signal to predatorArea class
		public var foodFish:Vector.<Entity> = new Vector.<Entity>(); // fish to attack first (before player)
		public var targetEntity:Entity; // current target entity .. to be eaten.. mm.. tasty fish yum yum yum.  (bart craves goldfish)
	}
}