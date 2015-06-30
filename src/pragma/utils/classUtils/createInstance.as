package pragma.utils.classUtils
{
	/**
	 * Cоздание экземпляра неизвестного заранее класса с неизвестным количеством аргументов.
	 * <br/><br/>
	 * 
	 * @author Lecosson
	 * @version 2012-02-22
	 * @param $class: класс, экземпляр которого нужно создать
	 * @param $args: список аргументов для конструктора класса
	 * @return возвращает объект типа, указанного в <code>$class</code>
	 * @throws может возвращать ошибку для неверного или слишком большого числа аргументов, неправильного значения в $class
	 * @see Пример вызова:
	 * <br/><code>
	 * var filter:GlowFilter = createInstance(GlowFilter, 0xFFFFFF, 1, 3, 3);
	 * </code><br/><br/>
	 */
	public function createInstance($class:Class, ...$args):* {
		//возможно, стоит сделать проверки и отлов ошибки на случай, если передается не класс, много аргументов или неправильные и т.п.
		var p:Array=$args.slice();
		function g():* { return p.shift();}
		switch ($args.length) {
			case 0: return new $class();
			case 1: return new $class(g());
			case 2: return new $class(g(), g());
			case 3: return new $class(g(), g(), g());
			case 4: return new $class(g(), g(), g(), g());
			case 5: return new $class(g(), g(), g(), g(), g());
			case 6: return new $class(g(), g(), g(), g(), g(), g());
			case 7: return new $class(g(), g(), g(), g(), g(), g(), g());
			case 8: return new $class(g(), g(), g(), g(), g(), g(), g(), g());
			case 9: return new $class(g(), g(), g(), g(), g(), g(), g(), g(), g());
			case 10: return new $class(g(), g(), g(), g(), g(), g(), g(), g(), g(), g());
			case 11: return new $class(g(), g(), g(), g(), g(), g(), g(), g(), g(), g(), g());
			case 12: return new $class(g(), g(), g(), g(), g(), g(), g(), g(), g(), g(), g(), g());
			case 13: return new $class(g(), g(), g(), g(), g(), g(), g(), g(), g(), g(), g(), g(), g());
			case 14: return new $class(g(), g(), g(), g(), g(), g(), g(), g(), g(), g(), g(), g(), g(), g());
			case 15: return new $class(g(), g(), g(), g(), g(), g(), g(), g(), g(), g(), g(), g(), g(), g(), g());
			case 16: return new $class(g(), g(), g(), g(), g(), g(), g(), g(), g(), g(), g(), g(), g(), g(), g(), g());
			case 17: return new $class(g(), g(), g(), g(), g(), g(), g(), g(), g(), g(), g(), g(), g(), g(), g(), g(), g());
			case 18: return new $class(g(), g(), g(), g(), g(), g(), g(), g(), g(), g(), g(), g(), g(), g(), g(), g(), g(), g());
			case 19: return new $class(g(), g(), g(), g(), g(), g(), g(), g(), g(), g(), g(), g(), g(), g(), g(), g(), g(), g(), g());
			case 20: return new $class(g(), g(), g(), g(), g(), g(), g(), g(), g(), g(), g(), g(), g(), g(), g(), g(), g(), g(), g(), g());
			// строго между нами, пацанами - это можно было бы сделать с помощью AS3eval, но запускать целый тамарин ради одного инстанса - перебор. 
			default: throw new Error("Too many arguments.");
		}
	}
}

 