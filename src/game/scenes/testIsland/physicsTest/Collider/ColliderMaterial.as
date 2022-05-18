package game.scenes.testIsland.physicsTest.Collider
{
	public class ColliderMaterial
	{
		public var bouncieness:Number;
		public var coeficientOfFriction:Number;
		
		public var bounceDeterminer:String;
		public var frictionDeterminer:String;
		
		public static const MAX:String = ">";
		public static const MIN:String = "<";
		public static const AVERAGE:String = "~";
		public static const MULTIPLY:String = "X";
		
		public static const BOUNCE:String = "bounce";
		public static const FRICTION:String = "friction";
		
		public function ColliderMaterial(bouncieness:Number = .5, bounceDeterminer:String = AVERAGE, coeficientOfFriction:Number = .5, frictionDeterminer:String = MULTIPLY)
		{
			this.bouncieness = bouncieness;
			this.bounceDeterminer = bounceDeterminer;
			this.coeficientOfFriction = coeficientOfFriction;
			this.frictionDeterminer = frictionDeterminer;
		}
		
		public static function getPropertyValue(property:String, mat1:ColliderMaterial, mat2:ColliderMaterial):Number
		{
			var value:Number = 0;
			if(property == BOUNCE)
				value = getValue(mat1.bouncieness,mat1.bounceDeterminer, mat2.bouncieness, mat2.bounceDeterminer);
			else
				value = getValue(mat1.coeficientOfFriction,mat1.frictionDeterminer, mat2.coeficientOfFriction, mat2.frictionDeterminer);
			return value;
		}
		
		public static function getValue(val1:Number, type1:String, val2:Number, type2:String):Number
		{
			var value:Number = 0;
			
			if(type1 == MIN || type2 == MIN)
				value = Math.min(val1, val2);
			else
			{
				if(type1 == MAX || type2 == MAX)
					value = Math.max(val1, val2);
				else
				{
					if(type1 == AVERAGE || type2 == AVERAGE)
						value = (val1 + val2) / 2;
					else
						value = val1 * val2;
				}
			}
			
			return value;
		}
	}
}