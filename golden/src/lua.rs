//! Вывод значений Rust как Luau-выражений для эталонов: f32 -> F(биты),
//! Vector3 -> V(биты, биты, биты), массивы -> таблицы, структуры -> obj!.
use skate_core::math::Vector3;

pub trait L { fn l(&self) -> String; }
impl L for f32 { fn l(&self) -> String { format!("F(0x{:08x})", self.to_bits()) } }
impl L for u32 { fn l(&self) -> String { self.to_string() } }
impl L for i32 { fn l(&self) -> String { self.to_string() } }
impl L for u8 { fn l(&self) -> String { self.to_string() } }
impl L for usize { fn l(&self) -> String { self.to_string() } }
impl L for bool { fn l(&self) -> String { self.to_string() } }
impl L for Vector3 { fn l(&self) -> String { format!("V(0x{:08x}, 0x{:08x}, 0x{:08x})", self.x.to_bits(), self.y.to_bits(), self.z.to_bits()) } }
impl<T: L, const N: usize> L for [T; N] { fn l(&self) -> String { format!("{{ {} }}", self.iter().map(|x| x.l()).collect::<Vec<_>>().join(", ")) } }
impl<T: L> L for Vec<T> { fn l(&self) -> String { format!("{{ {} }}", self.iter().map(|x| x.l()).collect::<Vec<_>>().join(", ")) } }
impl<T: L> L for Option<T> { fn l(&self) -> String { match self { Some(x) => x.l(), None => "nil".into() } } }
impl L for &str { fn l(&self) -> String { format!("{:?}", self) } }
impl L for String { fn l(&self) -> String { format!("{:?}", self) } }
impl<const N: usize> L for skate_core::point_graph::PointGraph<N> { fn l(&self) -> String { format!("{{ x = {}, y = {} }}", self.x.l(), self.y.l()) } }
impl L for skate_core::physics::force_queue::QueuedPointForce { fn l(&self) -> String { format!("{{ tag = {}, force_world = {}, point_body = {} }}", self.tag, self.force_world.l(), self.point_body.l()) } }

#[macro_export]
macro_rules! obj {
    ($($k:ident = $v:expr),* $(,)?) => {{
        use $crate::lua::L;
        let mut parts: Vec<String> = Vec::new();
        $( parts.push(format!("{} = {}", stringify!($k), ($v).l())); )*
        format!("{{ {} }}", parts.join(", "))
    }};
}
pub struct Raw(pub String);
impl L for Raw { fn l(&self) -> String { self.0.clone() } }

pub const HEADER: &str = "local rt = require(\"../../src/rt\")\nlocal F = rt.from_bits\nlocal function V(x, y, z) return vector.create(F(x), F(y), F(z)) end\n";
