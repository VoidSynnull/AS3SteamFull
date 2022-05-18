package game.scenes.carnival.apothecary.chemicals
{
	import flash.geom.Point;
	
	import game.scenes.carnival.apothecary.components.Molecules;
	
	import nape.constraint.Constraint;
	import nape.constraint.WeldJoint;
	import nape.geom.Vec2;
	import nape.phys.Body;
	import nape.space.Space;

	public class Compound
	{
		public function Compound($chemicals:Vector.<IChem>)
		{
			chemicals = $chemicals;
			
			// add reference to this compound in the chemicals
			for each(var chem:IChem in chemicals){
				chem.compound = this;
			}
		}
		
		public static function newCompound($compoundArray:Array, $molecules:Molecules):Compound{
			
			var chem1Class:Class;
			var chem2Class:Class;
			var chem3Class:Class;
			
			var chem1:IChem 
			var chem2:IChem 
			var chem3:IChem 
			
			var compound:Compound
			
			if($compoundArray[0].length == 2){ // compounds with 2 components
				
				chem1Class = $compoundArray[0][0];
				chem2Class = $compoundArray[0][1];
				
				chem1 = new chem1Class($molecules) as IChem;
				chem1.position = "left";
				chem1.reactions.push($compoundArray[1][0]);
				
				chem2 = new chem2Class($molecules) as IChem;
				chem2.position = "right";
				chem2.reactions.push($compoundArray[1][1]);
				
				compound= createCompound(chem1, chem2, $molecules);
				
				$molecules.compounds.push(compound);
				
				return compound;
			} else if($compoundArray[0].length == 3){ // compounds with 3 components
				
				chem1Class = $compoundArray[0][0];
				chem2Class = $compoundArray[0][1];
				chem3Class = $compoundArray[0][2];
				
				chem1 = new chem1Class($molecules) as IChem;
				chem1.position = "left";
				chem1.reactions.push($compoundArray[1][0]);
				
				chem2 = new chem2Class($molecules) as IChem;
				chem2.position = "middle";
				chem2.reactions.push($compoundArray[1][1][0]);
				chem2.reactions.push($compoundArray[1][1][1]);
				
				chem3 = new chem3Class($molecules) as IChem;
				chem3.position = "right";
				chem3.reactions.push($compoundArray[1][2]);
				
				compound = createCompound(chem1, chem2, $molecules);
				Compound.addToCompound(compound, chem3, $molecules);
				
				$molecules.compounds.push(compound);
				
				return compound;
			} else {
				return null;
			}
		}
		
		public static function createCompound($leftChem:IChem, $rightChem:IChem, $molecules:Molecules):Compound{
			
			// bond chemicals together in order
			bondChemicals($leftChem, $rightChem, $molecules.space);
			
			// create compound in memory
			var compound:Compound = new Compound(new <IChem>[$leftChem, $rightChem]);
			
			return compound;
		}
		
		public static function addToCompound($compound:Compound, $chem:IChem, $molecules:Molecules):void{
			
			// bond new chemical onto existing compound
			$compound.chemicals.push($chem);
			$chem.compound = $compound;
			
			// find middle chemical
			var midChem:IChem;
			
			for each(var chem:IChem in $compound.chemicals){
				if(chem.position == "middle"){
					midChem = chem;
				}
			}
			
			if($chem.position == "right"){
				bondChemicals(midChem, $chem, $molecules.space);
			} else {
				bondChemicals($chem, midChem, $molecules.space);
			}
		}
		
		public function breakCompound($compounds:Vector.<Compound>):void{
			
			// break bonds and make chemicals reactive
			for each(var chem:IChem in chemicals){
				// break constraints (welds)
				while (!chem.body.constraints.empty()) {
					chem.body.constraints.at(0).space = null;
				}
				
				// clear the compound reference
				chem.compound = null;
				
				// turn on collision detection
				chem.checkForCollisions();
				
				// make chem reactive
				chem.reactive = true;
				
				// reset bond offsets & rotation (if any)
				chem.resetBondOffset();
				chem.resetBondRotation();
			}
			
			// remove this from $compounds
			for(var c:int = 0; c < $compounds.length; c++){
				if($compounds[c] == this){
					$compounds.splice(c,1);
				}
			}
			
			// clear memory of this
			chemicals = null;
		}
		
		private static function bondChemicals($leftChem:IChem, $rightChem:IChem, $space:Space):void{
			var body1:Body = $leftChem.body;
			var body2:Body = $rightChem.body;
			
			var point1:Point = new Point(body1.position.x, body1.position.y);
			var point2:Point = new Point(body2.position.x, body2.position.y);
			var midPoint:Point = Point.interpolate(point1, point2, 0.5);
			
			var weldPoint:Vec2 = Vec2.get(midPoint.x,midPoint.y);
			
			// line up angles
			var dX:Number = point1.x - point2.x;
			var dY:Number = point1.y - point2.y;
			//var angle:Number = Math.atan2(dY, dX);
			
			var angle:Number = 90 * (Math.PI/180);
			
			body1.rotation = angle;
			body2.rotation = angle;

			// bring bodies together
			var b1point:Point = new Point(midPoint.x - $leftChem.bondPoint.x * Math.cos(angle), midPoint.y - $leftChem.bondPoint.y * Math.sin(angle));
			var b2point:Point = new Point(midPoint.x + $leftChem.bondPoint.x * Math.cos(angle), midPoint.y + $rightChem.bondPoint.y * Math.sin(angle));
			
			body1.position = new Vec2(b1point.x, b1point.y);
			body2.position = new Vec2(b2point.x, b2point.y);
			
			// weld them together
			var weld:WeldJoint = new WeldJoint(body1, body2, body1.worldPointToLocal(weldPoint, true), body2.worldPointToLocal(weldPoint, true));
			format(weld, $space);
			
			weldPoint.dispose();
			
			// apply bond offsets (if any)
			if($leftChem.rightBondRotation != 0){
				$rightChem.bondRotation($leftChem.rightBondRotation);
			}
			if($rightChem.leftBondRotation != 0){
				$leftChem.bondRotation($rightChem.leftBondRotation);
			}
			if($leftChem.rightBondOffset != null){
				$rightChem.bondOffset($leftChem.rightBondOffset);
			}
			if($rightChem.leftBondOffset != null){
				$leftChem.bondOffset($rightChem.leftBondOffset);
			}
			
		}
		
		private static function format(c:Constraint, $space:Space):void {
			c.stiff = true;
			c.maxForce = 30000;
			c.frequency = _frequency;
			c.damping = _damping;
			c.space = $space;
		};
		
		private static var _frequency:Number = 30.0;
		private static var _damping:Number = 10;
		
		public var dontBreak:Boolean = false;
		public var complete:Boolean = false;
		public var chemicals:Vector.<IChem>;
	}
}