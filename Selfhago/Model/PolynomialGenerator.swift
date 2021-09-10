//
//  PolynomialGenerator.swift
//  PolynomialGenerator
//
//  Created by bart Shin on 2021/09/06.
//	https://developer.apple.com/documentation/accelerate/finding_an_interpolating_polynomial_using_the_vandermonde_method#3521012

import simd
import Accelerate

class PolynomialGenerator<T>: ObservableObject where T: BinaryFloatingPoint {
	
	@Published private var points: [simd_float2]
	
	init(points: [(T, T)]) {
		self.points = []
		setPoints(points)
	}
	
	func setPoints<T>(_ points: [(T, T)]) where T: BinaryFloatingPoint {
		self.points = points.compactMap {
			simd_float2(Float($0.0), Float($0.1))
		}
	}
	
	func getResult(in range: ClosedRange<Float>, increment: Int = 1) -> [Float] {
		vDSP.evaluatePolynomial(usingCoefficients: coefficients,
								withVariables: vDSP.ramp(in: 0...1, count: Int(range.upperBound - range.lowerBound) / increment))
	}
	
	func getResult(for width: CGFloat) -> [Float] {
		vDSP.evaluatePolynomial(usingCoefficients: coefficients,
								withVariables: vDSP.ramp(withInitialValue: Float(0), increment: Float(1/width), count: Int(width)))
	}
	
	
	private var exponents: [Float] {
		(0 ..< points.count).map {
			return Float($0)
		}
	}
	
	private var vandermonde: [[Float]] {
		points.map { point in
			let bases = [Float](repeating: point.x,
								 count: points.count)
			return vForce.pow(bases: bases,
							  exponents: exponents)
		}
	}
	
	private var coefficients: [Float] {
		var a = vandermonde.flatMap { $0 }
		var b = points.map { $0.y }
		
		do {
			try solveLinearSystem(a: &a,
								  a_rowCount: points.count,
								  a_columnCount: points.count,
								  b: &b,
								  b_count: points.count)
		} catch {
			fatalError("Unable to solve linear system \n error \(error.localizedDescription)")
		}
		
		vDSP.reverse(&b)
		
		return b
	}
	
	private func solveLinearSystem(a: inout [Float],
						   a_rowCount: Int, a_columnCount: Int,
						   b: inout [Float],
						   b_count: Int) throws {
		
		var info = Int32(0)
		
		// 1: Specify transpose.
		var trans = Int8("T".utf8.first!)
		
		// 2: Define constants.
		var m = __CLPK_integer(a_rowCount)
		var n = __CLPK_integer(a_columnCount)
		var lda = __CLPK_integer(a_rowCount)
		var nrhs = __CLPK_integer(1) // assumes `b` is a column matrix
		var ldb = __CLPK_integer(b_count)
		
		
		// 3: Workspace query.
		var workDimension = Float(0)
		var minusOne = Int32(-1)
		
		
		sgels_(&trans, &m, &n,
			   &nrhs,
			   &a, &lda,
			   &b, &ldb,
			   &workDimension, &minusOne,
			   &info)
		
		if info != 0 {
			throw LAPACKError.internalError
		}
		
		// 4: Create workspace.
		var lwork = Int32(workDimension)
		var workspace = [Float](repeating: 0,
								 count: Int(workDimension))
		
		// 5: Solve linear system.
		sgels_(&trans, &m, &n,
			   &nrhs,
			   &a, &lda,
			   &b, &ldb,
			   &workspace, &lwork,
			   &info)
		
		if info < 0 {
			throw LAPACKError.parameterHasIllegalValue(parameterIndex: abs(Int(info)))
		} else if info > 0 {
			throw LAPACKError.diagonalElementOfTriangularFactorIsZero(index: Int(info))
		}
	}
	enum LAPACKError: Swift.Error {
		case internalError
		case parameterHasIllegalValue(parameterIndex: Int)
		case diagonalElementOfTriangularFactorIsZero(index: Int)
	}
}
